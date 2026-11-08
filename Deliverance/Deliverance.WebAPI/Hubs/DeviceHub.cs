using Deliverance.Model.Exceptions;
using Deliverance.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace Deliverance.WebAPI.Hubs;

[Authorize]
public class DeviceHub : Hub
{
    private readonly IDeviceService _deviceService;
    public const string CommandExecutedEvent = "CommandExecuted";

    public DeviceHub(IDeviceService deviceService)
    {
        _deviceService = deviceService;
    }
    public static string GroupName(int deviceId) => $"device-{deviceId}";

    public async Task JoinDeviceHub(int deviceId)
    {
        if (!Context.User!.IsAdmin())
        {
            throw new HubException("Only admins can follow scout commands.");
        }
        try
        {
            await _deviceService.GetByIdAsync(deviceId, Context.User!.GetUserId(), Context.User!.IsAdmin());
        }
        catch (Exception ex) when (ex is BusinessException or NotFoundException or ForbiddenException)
        {
            throw new HubException(ex.Message);
        }
        await Groups.AddToGroupAsync(Context.ConnectionId, GroupName(deviceId));
    }
}