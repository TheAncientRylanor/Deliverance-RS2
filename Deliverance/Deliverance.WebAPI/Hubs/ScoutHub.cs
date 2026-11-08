using Deliverance.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace Deliverance.WebAPI.Hubs;

[Authorize(AuthenticationSchemes = ScoutAuthDefaults.Scheme)]
public class ScoutHub : Hub
{
    public const string CommandQueuedEvent = "CommandQueued";

    public static string GroupName(int scoutId) => $"scout-{scoutId}";

    public override async Task OnConnectedAsync()
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, GroupName(Context.User!.GetScoutId()));
        await base.OnConnectedAsync();
    }
}
