using Deliverance.Model.RabbitMessages;
using Microsoft.Extensions.Logging;
using RabbitMQ.Client;
using System.Text.Json;

namespace Deliverance.Services.Messaging
{
    public sealed class RabbitMqReportEventSender : IAsyncDisposable
    {
        private readonly IConnection _connection;
        private readonly ILogger<RabbitMqReportEventSender> _logger;
        private readonly SemaphoreSlim _channelLock = new(1, 1);
        private IChannel? _channel;

        public RabbitMqReportEventSender(IConnection connection, ILogger<RabbitMqReportEventSender> logger)
        {
            _connection = connection;
            _logger = logger;
        }

        public async Task SendWithRetryAsync(ReportChangedMessage message, CancellationToken cancellationToken)
        {
            try
            {
                await RetryBackoff.ExecuteAsync(
                    () => SendOnceAsync(message, cancellationToken),
                    (ex, attempt, delay) => _logger.LogWarning(ex,
                        "Publishing {Type} for report {ReportId} failed (attempt {Attempt} of {MaxAttempts}), retrying in {Delay}s",
                        message.Type, message.ReportId, attempt, RetryBackoff.MaxAttempts, delay.TotalSeconds),
                    cancellationToken);
                _logger.LogInformation("Published {Type} for report {ReportId}", message.Type, message.ReportId);
            }
            catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,
                    "Gave up publishing {Type} for report {ReportId} after {MaxAttempts} attempts. Its statistics are out of date until the report changes again.",
                    message.Type, message.ReportId, RetryBackoff.MaxAttempts);
            }
        }

        private async Task SendOnceAsync(ReportChangedMessage message, CancellationToken cancellationToken)
        {
            await _channelLock.WaitAsync(cancellationToken);
            try
            {
                if (_channel is null || _channel.IsClosed)
                {
                    if (_channel is not null)
                    {
                        await _channel.DisposeAsync();
                    }
                    _channel = await _connection.CreateChannelAsync(cancellationToken: cancellationToken);
                    await _channel.ExchangeDeclareAsync(RabbitMqConstants.ReportEventsExchange, ExchangeType.Fanout,
                        durable: true, cancellationToken: cancellationToken);
                }

                var body = JsonSerializer.SerializeToUtf8Bytes(message);
                await _channel.BasicPublishAsync(
                    exchange: RabbitMqConstants.ReportEventsExchange,
                    routingKey: string.Empty,
                    mandatory: false,
                    basicProperties: new BasicProperties { Persistent = true },
                    body: body,
                    cancellationToken: cancellationToken);
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
