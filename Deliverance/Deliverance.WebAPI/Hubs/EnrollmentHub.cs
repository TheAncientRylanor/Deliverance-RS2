using Deliverance.Model.Exceptions;
using Deliverance.Model.Responses;
using Deliverance.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace Deliverance.WebAPI.Hubs
{
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
                throw new HubException(ex.Message);
            }

            await Groups.AddToGroupAsync(Context.ConnectionId, GroupName(enrollmentId));
            return enrollment;
        }
    }
}
