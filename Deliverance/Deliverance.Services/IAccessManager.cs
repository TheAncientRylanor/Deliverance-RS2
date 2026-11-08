using Deliverance.Model.Request;
using Deliverance.Model.Responses;

namespace Deliverance.Services
{
    public interface IAccessManager
    {
        Task<UserLoginResponse> LoginAsync(UserLoginRequest request);
        Task<UserLoginResponse> LoginWithRefreshTokenAsync(RefreshAccessTokenRequest request);
        Task<UserLoginResponse> AdminLoginAsync(UserLoginRequest request);
        Task<UserLoginResponse> AdminLoginWithRefreshTokenAsync(RefreshAccessTokenRequest request);
        Task ChangePasswordAsync(UserPasswordChangeRequest request, Guid userId);
        Task LogoutAsync(Guid userId, int sessionId);
    }
}
