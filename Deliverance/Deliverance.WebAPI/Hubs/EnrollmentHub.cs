using Deliverance.Model.Exceptions;
using Deliverance.Model.Responses;
using Deliverance.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace Deliverance.WebAPI.Hubs
{
    /// <summary>
    /// Real-time channel for the admin's device dialog. The admin joins the group of the
    /// enrollment they generated and receives <see cref="ClaimedEvent"/> once the scout
    /// claims the token. Scouts never connect here: they only call the REST claim endpoint.
    /// </summary>
    [Authorize]
    public class EnrollmentHub : Hub
    {
        public const string ClaimedEvent = "EnrollmentClaimed";

        private readonly IScoutEnrollmentService _scoutEnrollmentService;

        public EnrollmentHub(IScoutEnrollmentService scoutEnrollmentService)
        {
            _scoutEnrollmentService = scoutEnrollmentService;
        }

        public static string GroupName(int enrollmentId) => $"enrollment-{enrollmentId}";

        /// <summary>
        /// Subscribes this connection to one enrollment. Returns its current state, so a
        /// claim that happened before joining (or during a reconnect) isn't missed.
        /// </summary>
        public async Task<ScoutEnrollmentResponse> JoinEnrollment(int enrollmentId)
        {
            ScoutEnrollmentResponse enrollment;
            try
            {
                enrollment = await _scoutEnrollmentService.GetByIdAsync(
                    enrollmentId, Context.User!.GetUserId(), Context.User!.IsAdmin());
            }
            catch (Exception ex) when (ex is BusinessException or NotFoundException or ForbiddenException)
            {
                // Only HubException messages reach the client; others are hidden.
                throw new HubException(ex.Message);
            }

            await Groups.AddToGroupAsync(Context.ConnectionId, GroupName(enrollmentId));
            return enrollment;
        }

        public Task LeaveEnrollment(int enrollmentId)
            => Groups.RemoveFromGroupAsync(Context.ConnectionId, GroupName(enrollmentId));
    }
}
