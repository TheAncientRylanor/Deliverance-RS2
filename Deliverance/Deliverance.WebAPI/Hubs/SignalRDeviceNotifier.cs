using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Microsoft.AspNetCore.SignalR;

namespace Deliverance.WebAPI.Hubs
{

    public class SinalRDeviceNotifier : IDeviceNotifier
    {
        private readonly IHubContext<DeviceHub> _hubContext;
        private readonly ILogger<SinalRDeviceNotifier> _logger;
        public SinalRDeviceNotifier(IHubContext<DeviceHub> hubContext,
          ILogger<SinalRDeviceNotifier> logger)
        {
            _hubContext = hubContext;
            _logger = logger;
        }

        public async Task CommandUpdated(ScoutCommandResponse request)
        {
            try
            {
                await _hubContext.Clients
                    .Group(DeviceHub.GroupName(request.DeviceId))
                    .SendAsync(DeviceHub.CommandQueuedEvent, request);
            }
            catch (Exception ex)
            {
                // The claim is already saved; the admin's dialog still picks it up when it
                // (re)joins the group, so a failed push mustn't fail the scout's request.
                _logger.LogWarning(ex, "Could not push command {CommandId} to scout {ScoutId}", request.Id, request.ScoutId);
            }
        }
    }
}
