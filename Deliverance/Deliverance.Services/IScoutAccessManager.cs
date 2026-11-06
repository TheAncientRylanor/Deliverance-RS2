using Deliverance.Model.Request;
using Deliverance.Model.Responses;

namespace Deliverance.Services
{
    public interface IScoutAccessManager
    {
        /// <summary>
        /// Exchanges a scout secret for a short-lived scout JWT. Returns PendingApproval
        /// (no token) while the admin hasn't saved the device yet, Disabled (no token)
        /// while an admin has the scout disabled, and throws UnauthorizedAccessException
        /// (401) for an unknown, cancelled or revoked secret.
        /// </summary>
        Task<ScoutTokenResponse> CreateTokenAsync(ScoutTokenRequest request);
    }
}
