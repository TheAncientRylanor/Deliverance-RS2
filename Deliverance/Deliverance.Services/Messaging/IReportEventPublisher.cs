namespace Deliverance.Services.Messaging
{
    public interface IReportEventPublisher
    {
        Task PublishAsync(ReportChangedMessage message);
    }
}
