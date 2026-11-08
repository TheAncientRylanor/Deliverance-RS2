using Deliverance.Model.Responses;
using Deliverance.Services.Messaging;
using Microsoft.AspNetCore.SignalR;

namespace Deliverance.WebAPI.Hubs
{

    public class SignalRScoutNotifier : IScoutNotifier
    {
        private readonly IHubContext<ScoutHub> _hubContext;
        private readonly ILogger<SignalRScoutNotifier> _logger;
        public SignalRScoutNotifier(IHubContext<ScoutHub> hubContext,
          ILogger<SignalRScoutNotifier> logger)
        {
            _hubContext = hubContext;
            _logger = logger;
        }

        public async Task CommandSent(ScoutCommandResponse request)
        {
            try
            {
                await _hubContext.Clients
                    .Group(ScoutHub.GroupName(request.ScoutId))
                    .SendAsync(ScoutHub.CommandQueuedEvent, request);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Could not push command {CommandId} to scout {ScoutId}", request.Id, request.ScoutId);
            }
        }
    }
}
