using Deliverance.Model.Exceptions;
using Deliverance.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;


[Authorize(AuthenticationSchemes = ScoutAuthDefaults.Scheme)]
public class ScoutHub : Hub
{

    public readonly IScoutService _scoutService;
    public const string CommandQueuedEvent = "CommandQueued";

    public ScoutHub(IScoutService scoutService)
    {
        _scoutService = scoutService;
    }
    public static string GroupName(int scoutID) => $"scout-{scoutID}";

    public override async Task OnConnectedAsync()
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, GroupName(Context.User!.GetScoutId()));
        await base.OnConnectedAsync();
    }
    public Task LeaveScoutHub()
    => Groups.RemoveFromGroupAsync(Context.ConnectionId, GroupName(Context.User!.GetScoutId()));
}