using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

// Nothing to join: messages go to Clients.User, which finds a user's connections
// from the NameIdentifier claim, so everyone only receives their own notifications.
[Authorize]
public class NotificationHub : Hub
{
    public const string NotificationCreatedEvent = "NotificationCreated";
}
