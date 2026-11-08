using Deliverance.Model.Responses;

namespace Deliverance.Services.Messaging
{
    public interface INotificationNotifier
    {
        Task NotificationCreatedAsync(Guid userId, NotificationResponse notification);
    }
}
