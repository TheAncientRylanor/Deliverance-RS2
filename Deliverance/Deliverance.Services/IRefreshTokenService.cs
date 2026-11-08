using Deliverance.Services.Database;

namespace Deliverance.Services
{
    public interface IRefreshTokenService
    {
        Task<RefreshTokens?> GetStoredTokenAsync(string refreshToken);
        RefreshTokens Add(Guid userId, string refreshToken, DateTime expiresAt);
        void Rotate(RefreshTokens session, string newRefreshToken, DateTime expiresAt);
        Task RemoveAsync(int sessionId, Guid userId);
        Task RemoveExpiredForUserAsync(Guid userId);
        Task RemoveAllForUserAsync(Guid userId);
    }
}
