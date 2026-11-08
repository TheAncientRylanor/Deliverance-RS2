using Deliverance.Model.Responses;

namespace Deliverance.Services.Messaging
{
    /// <summary>
    /// Pushes a saved notification to its recipient's open apps.
    /// Implemented in the WebAPI (SignalR), so the services stay free of hub code.
    /// </summary>
    public interface INotificationNotifier
    {
        Task NotificationCreatedAsync(Guid userId, NotificationResponse notification);
    }
}
