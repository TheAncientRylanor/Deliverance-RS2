using Deliverance.Model.Request;
using Deliverance.Model.Responses;

namespace Deliverance.Services
{
    public interface IScoutEnrollmentService
    {
        /// <summary>Creates a pending enrollment and returns its one-time plain token.</summary>
        Task<ScoutEnrollmentTokenResponse> CreateAsync(Guid userId, bool isAdmin);

        Task<ScoutEnrollmentResponse> GetByIdAsync(int id, Guid userId, bool isAdmin);

        Task CancelAsync(int id, Guid userId, bool isAdmin);

        /// <summary>
        /// Called by the scout app: stores its device information, notifies the admin and
        /// returns the scout's long-term secret.
        /// </summary>
        Task<ScoutEnrollmentClaimResponse> ClaimAsync(ScoutEnrollmentClaimRequest request);

        /// <summary>
        /// Loads (tracked) the claimed enrollments the given devices refer to, and throws if
        /// any of them can't be linked by this user. Null ids are skipped.
        /// </summary>
        Task<IReadOnlyDictionary<int, ScoutEnrollment>> GetClaimedForLinkingAsync(IEnumerable<int?> enrollmentIds, Guid userId);

        /// <summary>
        /// Creates the device's Scout and completes the enrollment. Doesn't save:
        /// the caller saves it together with the office.
        /// </summary>
        void AttachToDevice(ScoutEnrollment enrollment, Device device);
    }
}
