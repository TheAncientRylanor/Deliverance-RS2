using Deliverance.Services.Database;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;
using System.Text;

namespace Deliverance.Services
{
    public class RefreshTokenService : IRefreshTokenService
    {
        private readonly DbSet<RefreshTokens> _refreshTokens;

        public RefreshTokenService(DeliveranceDbContext context)
        {
            _refreshTokens = context.RefreshTokens;
        }

        public async Task<RefreshTokens?> GetStoredTokenAsync(string refreshToken)
        {
            var hash = Hash(refreshToken);
            return await _refreshTokens.FirstOrDefaultAsync(rt => rt.Token == hash);
        }

        public RefreshTokens Add(Guid userId, string refreshToken, DateTime expiresAt)
        {
            var row = new RefreshTokens
            {
                UserUUID = userId,
                Token = Hash(refreshToken),
                ExpiresAt = expiresAt,
            };
            _refreshTokens.Add(row);
            return row;
        }

        public void Rotate(RefreshTokens session, string newRefreshToken, DateTime expiresAt)
        {
            session.Token = Hash(newRefreshToken);
            session.ExpiresAt = expiresAt;
        }

        public async Task RemoveAsync(int sessionId, Guid userId)
        {
            var session = await _refreshTokens.FirstOrDefaultAsync(rt => rt.Id == sessionId && rt.UserUUID == userId);
            if (session != null)
            {
                _refreshTokens.Remove(session);
            }
        }

        public async Task RemoveExpiredForUserAsync(Guid userId)
        {
            var now = DateTime.UtcNow;
            var expired = await _refreshTokens.Where(rt => rt.UserUUID == userId && rt.ExpiresAt < now).ToListAsync();
            _refreshTokens.RemoveRange(expired);
        }

        public async Task RemoveAllForUserAsync(Guid userId)
        {
            var tokens = await _refreshTokens.Where(rt => rt.UserUUID == userId).ToListAsync();
            _refreshTokens.RemoveRange(tokens);
        }

        private static string Hash(string refreshToken)
            => Convert.ToBase64String(SHA256.HashData(Encoding.UTF8.GetBytes(refreshToken)));
    }
}
