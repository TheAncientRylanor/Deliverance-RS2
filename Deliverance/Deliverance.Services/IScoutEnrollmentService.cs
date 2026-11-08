using Deliverance.Services.Database;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;

namespace Deliverance.Services
{
    public interface IScoutEnrollmentService
    {
        Task<ScoutEnrollmentTokenResponse> CreateAsync(Guid userId, bool isAdmin);

        Task<ScoutEnrollmentResponse> GetByIdAsync(int id, Guid userId, bool isAdmin);

        Task CancelAsync(int id, Guid userId, bool isAdmin);

        Task<ScoutEnrollmentClaimResponse> ClaimAsync(ScoutEnrollmentClaimRequest request);

        Task<IReadOnlyDictionary<int, ScoutEnrollment>> GetClaimedForLinkingAsync(IEnumerable<int?> enrollmentIds, Guid userId);

        void AttachToDevice(ScoutEnrollment enrollment, Device device);
    }
}
