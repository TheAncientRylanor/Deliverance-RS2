using Deliverance.Services.Database;
using Deliverance.Services.Messaging;
using Microsoft.EntityFrameworkCore;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;
using System.Text.Json;

namespace Deliverance.WebAPI.BackgroundServices
{
    /// <summary>
    /// Keeps ReportStatistics in step with reports. A failing message is retried on
    /// <see cref="RetryBackoff"/>, then moved to the failed queue so it can't loop forever.
    /// </summary>
    public class ReportStatisticsConsumer : BackgroundService
    {
        private const int MaxLoggedBodyLength = 1000;

        private readonly IConnection _connection;
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<ReportStatisticsConsumer> _logger;
        private IChannel? _channel;

        public ReportStatisticsConsumer(IConnection connection, IServiceScopeFactory scopeFactory, ILogger<ReportStatisticsConsumer> logger)
        {
            _connection = connection;
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            try
            {
                await RetryBackoff.ExecuteAsync(
                    () => StartConsumingAsync(stoppingToken),
                    (ex, attempt, delay) => _logger.LogWarning(ex,
                        "Report statistics worker could not start (attempt {Attempt} of {MaxAttempts}), retrying in {Delay}s",
                        attempt, RetryBackoff.MaxAttempts, delay.TotalSeconds),
                    stoppingToken);
                _logger.LogInformation("Report statistics worker is consuming {Queue}", RabbitMqConstants.ReportStatisticsQueue);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                _logger.LogInformation("Report statistics worker stopped before it started consuming");
            }
            catch (Exception ex)
            {
                // Caught so the API keeps running, but logged loudly: statistics stop updating.
                _logger.LogCritical(ex,
                    "Report statistics worker could not start after {MaxAttempts} attempts and has stopped. Report statistics won't update until the API restarts.",
                    RetryBackoff.MaxAttempts);
            }
        }

        private async Task StartConsumingAsync(CancellationToken stoppingToken)
        {
            // A failed earlier attempt may have left a channel behind.
            if (_channel is not null)
            {
                await _channel.DisposeAsync();
            }
            var channel = await _connection.CreateChannelAsync(cancellationToken: stoppingToken);
            _channel = channel;
            channel.ChannelShutdownAsync += (_, args) =>
            {
                if (args.Initiator == ShutdownInitiator.Application)
                {
                    _logger.LogInformation("Report statistics channel closed by the app");
                }
                else
                {
                    _logger.LogWarning(args.Exception,
                        "Report statistics channel closed ({Initiator}, {ReplyCode} {ReplyText}). It reopens if the connection recovers.",
                        args.Initiator, args.ReplyCode, args.ReplyText);
                }
                return Task.CompletedTask;
            };
            channel.CallbackExceptionAsync += (_, args) =>
            {
                _logger.LogError(args.Exception, "Error in a report statistics channel callback");
                return Task.CompletedTask;
            };

            await channel.ExchangeDeclareAsync(RabbitMqConstants.ReportEventsExchange, ExchangeType.Fanout, durable: true, cancellationToken: stoppingToken);
            await channel.QueueDeclareAsync(RabbitMqConstants.ReportStatisticsQueue, durable: true, exclusive: false, autoDelete: false, cancellationToken: stoppingToken);
            await channel.QueueBindAsync(RabbitMqConstants.ReportStatisticsQueue, RabbitMqConstants.ReportEventsExchange, routingKey: string.Empty, cancellationToken: stoppingToken);
            await channel.QueueDeclareAsync(RabbitMqConstants.ReportStatisticsFailedQueue, durable: true, exclusive: false, autoDelete: false, cancellationToken: stoppingToken);
            // Messages are handled one at a time, so there's no point holding many unacked ones.
            await channel.BasicQosAsync(prefetchSize: 0, prefetchCount: 10, global: false, cancellationToken: stoppingToken);

            var consumer = new AsyncEventingBasicConsumer(channel);
            consumer.ReceivedAsync += async (_, eventArgs) =>
            {
                try
                {
                    await HandleAsync(channel, eventArgs, stoppingToken);
                }
                catch (Exception ex)
                {
                    // HandleAsync deals with its own failures; this is only for the unexpected.
                    _logger.LogError(ex,
                        "Unexpected error handling report statistics message {DeliveryTag}. Body: {Body}",
                        eventArgs.DeliveryTag, BodyForLog(eventArgs.Body));
                }
            };

            await channel.BasicConsumeAsync(RabbitMqConstants.ReportStatisticsQueue, autoAck: false, consumer: consumer, cancellationToken: stoppingToken);
        }

        private async Task HandleAsync(IChannel channel, BasicDeliverEventArgs eventArgs, CancellationToken stoppingToken)
        {
            ReportChangedMessage? message = null;
            JsonException? readError = null;
            try
            {
                message = JsonSerializer.Deserialize<ReportChangedMessage>(eventArgs.Body.Span);
            }
            catch (JsonException ex)
            {
                readError = ex;
            }

            // Retrying won't make an unreadable message readable.
            if (message is null)
            {
                _logger.LogError(readError,
                    "Report statistics message {DeliveryTag} can't be read, moving it to {FailedQueue}. Body: {Body}",
                    eventArgs.DeliveryTag, RabbitMqConstants.ReportStatisticsFailedQueue, BodyForLog(eventArgs.Body));
                await MoveToFailedQueueAsync(channel, eventArgs);
                return;
            }

            try
            {
                await RetryBackoff.ExecuteAsync(
                    () => ProcessMessageAsync(message, stoppingToken),
                    (ex, attempt, delay) => _logger.LogWarning(ex,
                        "Updating statistics for report {ReportId} ({Type}) failed (attempt {Attempt} of {MaxAttempts}, redelivered: {Redelivered}), retrying in {Delay}s",
                        message.ReportId, message.Type, attempt, RetryBackoff.MaxAttempts, eventArgs.Redelivered, delay.TotalSeconds),
                    stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                _logger.LogInformation(
                    "Stopping while statistics for report {ReportId} ({Type}) were being updated; the message goes back on the queue",
                    message.ReportId, message.Type);
                await RequeueAsync(channel, eventArgs);
                return;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,
                    "Gave up updating statistics for report {ReportId} ({Type}) after {MaxAttempts} attempts, moving it to {FailedQueue}. Body: {Body}",
                    message.ReportId, message.Type, RetryBackoff.MaxAttempts, RabbitMqConstants.ReportStatisticsFailedQueue, BodyForLog(eventArgs.Body));
                await MoveToFailedQueueAsync(channel, eventArgs);
                return;
            }

            await channel.BasicAckAsync(eventArgs.DeliveryTag, multiple: false);
            _logger.LogInformation("Updated statistics for report {ReportId} ({Type})", message.ReportId, message.Type);
        }

        /// <summary>
        /// Copies the message to the failed queue, then acks the original. If that fails, the
        /// message goes back on the main queue and is retried again later.
        /// </summary>
        private async Task MoveToFailedQueueAsync(IChannel channel, BasicDeliverEventArgs eventArgs)
        {
            try
            {
                await channel.BasicPublishAsync(
                    exchange: string.Empty,
                    routingKey: RabbitMqConstants.ReportStatisticsFailedQueue,
                    mandatory: false,
                    basicProperties: new BasicProperties { Persistent = true },
                    body: eventArgs.Body);
                await channel.BasicAckAsync(eventArgs.DeliveryTag, multiple: false);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,
                    "Could not move message {DeliveryTag} to {FailedQueue}; it goes back on {Queue}",
                    eventArgs.DeliveryTag, RabbitMqConstants.ReportStatisticsFailedQueue, RabbitMqConstants.ReportStatisticsQueue);
                await RequeueAsync(channel, eventArgs);
            }
        }

        private async Task RequeueAsync(IChannel channel, BasicDeliverEventArgs eventArgs)
        {
            try
            {
                await channel.BasicNackAsync(eventArgs.DeliveryTag, multiple: false, requeue: true);
            }
            catch (Exception ex)
            {
                // RabbitMQ requeues unacked messages itself when the channel closes.
                _logger.LogWarning(ex,
                    "Could not requeue message {DeliveryTag}; RabbitMQ requeues it when the channel closes",
                    eventArgs.DeliveryTag);
            }
        }

        private static string BodyForLog(ReadOnlyMemory<byte> body)
        {
            var text = Encoding.UTF8.GetString(body.Span);
            return text.Length <= MaxLoggedBodyLength ? text : text[..MaxLoggedBodyLength] + "...";
        }

        private async Task ProcessMessageAsync(ReportChangedMessage message, CancellationToken cancellationToken)
        {
            using var scope = _scopeFactory.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<DeliveranceDbContext>();

            var existingRows = await dbContext.ReportStatistics
                .Where(x => x.ReportId == message.ReportId)
                .ToListAsync(cancellationToken);
            dbContext.ReportStatistics.RemoveRange(existingRows);

            if (message.Type != ChangeType.Removed)
            {
                var report = await dbContext.Reports
                    .Include(x => x.OfficeReports)
                        .ThenInclude(x => x.DeviceReports)
                    .FirstOrDefaultAsync(x => x.Id == message.ReportId, cancellationToken);

                if (report != null)
                {
                    foreach (var officeReport in report.OfficeReports)
                    {
                        foreach (var deviceReport in officeReport.DeviceReports)
                        {
                            dbContext.ReportStatistics.Add(new ReportStatistics
                            {
                                ReportId = report.Id,
                                OfficeReportId = officeReport.Id,
                                OfficeId = officeReport.OfficeId,
                                DeviceId = deviceReport.DeviceId,
                                DateReported = report.DateReported,
                                UserId = report.UserUUID,
                            });
                        }
                    }
                }
            }

            await dbContext.SaveChangesAsync(cancellationToken);
        }

        public override void Dispose()
        {
            _channel?.Dispose();
            base.Dispose();
        }
    }
}
