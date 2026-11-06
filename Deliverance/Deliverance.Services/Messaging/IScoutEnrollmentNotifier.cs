using Deliverance.Model.Responses;

namespace Deliverance.Services.Messaging
{
    /// <summary>
    /// Tells the admin who generated an enrollment token that a scout has claimed it.
    /// Implemented in the WebAPI (SignalR), so the services stay free of hub code.
    /// </summary>
    public interface IScoutEnrollmentNotifier
    {
        Task EnrollmentClaimedAsync(ScoutEnrollmentResponse enrollment);
    }
}
