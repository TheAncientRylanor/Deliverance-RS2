using RabbitMQ.Client;
using System.Text.Json;

namespace Deliverance.Services.Messaging
{
    public class RabbitMqReportEventPublisher : IReportEventPublisher
    {
        private readonly IConnection _connection;

        public RabbitMqReportEventPublisher(IConnection connection)
        {
            _connection = connection;
        }

        public async Task PublishAsync(ReportChangedMessage message)
        {
            using var channel = await _connection.CreateChannelAsync();

            await channel.ExchangeDeclareAsync(RabbitMqConstants.ReportEventsExchange, ExchangeType.Fanout, durable: true);

            var body = JsonSerializer.SerializeToUtf8Bytes(message);

            await channel.BasicPublishAsync(
                exchange: RabbitMqConstants.ReportEventsExchange,
                routingKey: string.Empty,
                body: body);
        }
    }
}
