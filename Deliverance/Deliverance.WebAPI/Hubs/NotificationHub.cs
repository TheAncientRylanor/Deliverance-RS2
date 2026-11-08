using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace Deliverance.WebAPI.Hubs;

[Authorize]
public class NotificationHub : Hub
{
    public const string NotificationCreatedEvent = "NotificationCreated";
}
