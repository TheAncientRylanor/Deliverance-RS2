using Deliverance.Services.Messaging;
using Deliverance.Model.Responses;
using Microsoft.AspNetCore.SignalR;

namespace Deliverance.WebAPI.Hubs
{

    public class SignalRDeviceNotifier : IDeviceNotifier
    {
        private readonly IHubContext<DeviceHub> _hubContext;
        private readonly ILogger<SignalRDeviceNotifier> _logger;
        public SignalRDeviceNotifier(IHubContext<DeviceHub> hubContext,
          ILogger<SignalRDeviceNotifier> logger)
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
                    .SendAsync(DeviceHub.CommandExecutedEvent, request);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Could not push command {CommandId} to scout {ScoutId}", request.Id, request.ScoutId);
            }
        }
    }
}
