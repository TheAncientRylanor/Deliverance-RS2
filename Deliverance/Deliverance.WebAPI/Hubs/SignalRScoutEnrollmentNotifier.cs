using Deliverance.Model.Responses;
using Deliverance.Services.Messaging;
using Microsoft.AspNetCore.SignalR;

namespace Deliverance.WebAPI.Hubs
{
    public class SignalRScoutEnrollmentNotifier : IScoutEnrollmentNotifier
    {
        private readonly IHubContext<EnrollmentHub> _hubContext;
        private readonly ILogger<SignalRScoutEnrollmentNotifier> _logger;

        public SignalRScoutEnrollmentNotifier(IHubContext<EnrollmentHub> hubContext,
            ILogger<SignalRScoutEnrollmentNotifier> logger)
        {
            _hubContext = hubContext;
            _logger = logger;
        }

        public async Task EnrollmentClaimedAsync(ScoutEnrollmentResponse enrollment)
        {
            try
            {
                await _hubContext.Clients
                    .Group(EnrollmentHub.GroupName(enrollment.Id))
                    .SendAsync(EnrollmentHub.ClaimedEvent, enrollment);
            }
            catch (Exception ex)
            {
                // The claim is already saved; the admin's dialog still picks it up when it
                // (re)joins the group, so a failed push mustn't fail the scout's request.
                _logger.LogWarning(ex, "Could not push claim of scout enrollment {EnrollmentId}", enrollment.Id);
            }
        }
    }
}
