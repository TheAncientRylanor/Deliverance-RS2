using Deliverance.Model.Exceptions;
using Deliverance.Model.Responses;
using Deliverance.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;


[Authorize]
public class DeviceHub : Hub
{

    public readonly IDeviceService _deviceService;
    public const string CommandQueuedEvent = "CommandExecuted";

    public DeviceHub(IDeviceService deviceService)
    {
        _deviceService = deviceService;
    }
    public static string GroupName(int deviceID) => $"device-{deviceID}";

    public async Task JoinDeviceHub(int deviceId)
    {
        // Command output can hold anything the device prints, and only admins send
        // commands, so only admins may watch them.
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
    public Task LeaveDeviceHub(int deviceId)
    => Groups.RemoveFromGroupAsync(Context.ConnectionId, GroupName(deviceId));
}