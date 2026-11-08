using Deliverance.Model.Responses;
using Deliverance.Services.Messaging;
using Microsoft.AspNetCore.SignalR;

namespace Deliverance.WebAPI.Hubs
{
    public class SignalRNotificationNotifier : INotificationNotifier
    {
        private readonly IHubContext<NotificationHub> _hubContext;
        private readonly ILogger<SignalRNotificationNotifier> _logger;

        public SignalRNotificationNotifier(IHubContext<NotificationHub> hubContext,
            ILogger<SignalRNotificationNotifier> logger)
        {
            _hubContext = hubContext;
            _logger = logger;
        }

        public async Task NotificationCreatedAsync(Guid userId, NotificationResponse notification)
        {
            try
            {
                await _hubContext.Clients
                    .User(userId.ToString())
                    .SendAsync(NotificationHub.NotificationCreatedEvent, notification);
            }
            catch (Exception ex)
            {
                // The notification is already saved, so the app still gets it on its next load.
                _logger.LogWarning(ex, "Could not push notification {NotificationId} to user {UserId}", notification.Id, userId);
            }
        }
    }
}
