using Microsoft.Extensions.Logging;
using RabbitMQ.Client;
using System.Text.Json;

namespace Deliverance.Services.Messaging
{
    /// <summary>
    /// Registered as a singleton: one channel is reused for every publish, guarded by a lock
    /// because a channel must not be used by two publishes at once.
    /// </summary>
    public sealed class RabbitMqReportEventPublisher : IReportEventPublisher, IAsyncDisposable
    {
        private readonly IConnection _connection;
        private readonly ILogger<RabbitMqReportEventPublisher> _logger;
        private readonly SemaphoreSlim _channelLock = new(1, 1);
        private IChannel? _channel;

        public RabbitMqReportEventPublisher(IConnection connection, ILogger<RabbitMqReportEventPublisher> logger)
        {
            _connection = connection;
            _logger = logger;
        }

        /// <summary>
        /// The report is already saved when this is called, so a broker problem must not fail
        /// the request. Publishing and its retries run in the background, and every failure is logged.
        /// </summary>
        public Task PublishAsync(ReportChangedMessage message)
        {
            _ = Task.Run(() => PublishWithRetryAsync(message));
            return Task.CompletedTask;
        }

        private async Task PublishWithRetryAsync(ReportChangedMessage message)
        {
            try
            {
                await RetryBackoff.ExecuteAsync(
                    () => PublishOnceAsync(message),
                    (ex, attempt, delay) => _logger.LogWarning(ex,
                        "Publishing {Type} for report {ReportId} failed (attempt {Attempt} of {MaxAttempts}), retrying in {Delay}s",
                        message.Type, message.ReportId, attempt, RetryBackoff.MaxAttempts, delay.TotalSeconds));
                _logger.LogInformation("Published {Type} for report {ReportId}", message.Type, message.ReportId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,
                    "Gave up publishing {Type} for report {ReportId} after {MaxAttempts} attempts. Its statistics are out of date until the report changes again.",
                    message.Type, message.ReportId, RetryBackoff.MaxAttempts);
            }
        }

        private async Task PublishOnceAsync(ReportChangedMessage message)
        {
            await _channelLock.WaitAsync();
            try
            {
                if (_channel is null || _channel.IsClosed)
                {
                    if (_channel is not null)
                    {
                        await _channel.DisposeAsync();
                    }
                    _channel = await _connection.CreateChannelAsync();
                    await _channel.ExchangeDeclareAsync(RabbitMqConstants.ReportEventsExchange, ExchangeType.Fanout, durable: true);
                }

                var body = JsonSerializer.SerializeToUtf8Bytes(message);
                // Persistent, so a queued message survives a broker restart (the queue is durable).
                await _channel.BasicPublishAsync(
                    exchange: RabbitMqConstants.ReportEventsExchange,
                    routingKey: string.Empty,
                    mandatory: false,
                    basicProperties: new BasicProperties { Persistent = true },
                    body: body);
            }
            finally
            {
                _channelLock.Release();
            }
        }

        public async ValueTask DisposeAsync()
        {
            if (_channel is not null)
            {
                await _channel.DisposeAsync();
            }
            _channelLock.Dispose();
        }
    }
}
