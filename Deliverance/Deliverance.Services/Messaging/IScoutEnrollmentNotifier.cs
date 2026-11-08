using Deliverance.Model.Responses;

namespace Deliverance.Services.Messaging
{
    public interface IScoutEnrollmentNotifier
    {
        Task EnrollmentClaimedAsync(ScoutEnrollmentResponse enrollment);
    }
}
