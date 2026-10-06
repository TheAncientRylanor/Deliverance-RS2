using Deliverance.Services.Database;
using Deliverance.Services.Messaging;
using Microsoft.EntityFrameworkCore;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text.Json;

namespace Deliverance.WebAPI.BackgroundServices
{
    public class ReportStatisticsConsumer : BackgroundService
    {
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
            _channel = await _connection.CreateChannelAsync(cancellationToken: stoppingToken);

            await _channel.ExchangeDeclareAsync(RabbitMqConstants.ReportEventsExchange, ExchangeType.Fanout, durable: true, cancellationToken: stoppingToken);
            await _channel.QueueDeclareAsync(RabbitMqConstants.ReportStatisticsQueue, durable: true, exclusive: false, autoDelete: false, cancellationToken: stoppingToken);
            await _channel.QueueBindAsync(RabbitMqConstants.ReportStatisticsQueue, RabbitMqConstants.ReportEventsExchange, routingKey: string.Empty, cancellationToken: stoppingToken);

            var consumer = new AsyncEventingBasicConsumer(_channel);
            consumer.ReceivedAsync += async (sender, eventArgs) =>
            {
                try
                {
                    var message = JsonSerializer.Deserialize<ReportChangedMessage>(eventArgs.Body.Span);
                    if (message != null)
                    {
                        await ProcessMessageAsync(message);
                    }
                    await _channel.BasicAckAsync(eventArgs.DeliveryTag, multiple: false);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to process report statistics message for delivery tag {DeliveryTag}", eventArgs.DeliveryTag);
                    await _channel.BasicNackAsync(eventArgs.DeliveryTag, multiple: false, requeue: true);
                }
            };

            await _channel.BasicConsumeAsync(RabbitMqConstants.ReportStatisticsQueue, autoAck: false, consumer: consumer, cancellationToken: stoppingToken);
        }

        private async Task ProcessMessageAsync(ReportChangedMessage message)
        {
            using var scope = _scopeFactory.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<DeliveranceDbContext>();

            var existingRows = await dbContext.ReportStatistics
                .Where(x => x.ReportId == message.ReportId)
                .ToListAsync();
            dbContext.ReportStatistics.RemoveRange(existingRows);

            if (message.Type != ChangeType.Removed)
            {
                var report = await dbContext.Reports
                    .Include(x => x.OfficeReports)
                        .ThenInclude(x => x.DeviceReports)
                    .FirstOrDefaultAsync(x => x.Id == message.ReportId);

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

            await dbContext.SaveChangesAsync();
        }
    }
}
