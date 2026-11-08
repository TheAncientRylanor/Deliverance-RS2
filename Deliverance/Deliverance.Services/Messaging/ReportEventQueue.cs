using Deliverance.Model.RabbitMessages;
using System.Threading.Channels;

namespace Deliverance.Services.Messaging
{
    public sealed class ReportEventQueue : IReportEventPublisher
    {
        private readonly Channel<ReportChangedMessage> _channel = Channel.CreateUnbounded<ReportChangedMessage>(
            new UnboundedChannelOptions { SingleReader = true });

        public ChannelReader<ReportChangedMessage> Reader => _channel.Reader;

        public Task PublishAsync(ReportChangedMessage message)
        {
            if (!_channel.Writer.TryWrite(message))
            {
                throw new InvalidOperationException("The report event queue is closed because the app is shutting down.");
            }
            return Task.CompletedTask;
        }

        public void Complete() => _channel.Writer.TryComplete();
    }
}
