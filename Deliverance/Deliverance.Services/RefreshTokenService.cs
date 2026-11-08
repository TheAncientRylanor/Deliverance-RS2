using Deliverance.Services.Database;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Deliverance.Services
{
    public class RefreshTokenService : IRefreshTokenService
    {
        private readonly DeliveranceDbContext _context;
        private readonly DbSet<RefreshTokens> _refreshTokens;

        public RefreshTokenService(DeliveranceDbContext context)
        {
            _context = context;
            _refreshTokens = _context.RefreshTokens;
        }

        public async Task<RefreshTokens?> GetStoredTokenAsync(string refreshToken)
        {
            return await _refreshTokens.FirstOrDefaultAsync(rt => rt.Token == refreshToken);
        }

        // Add and RemoveAllForUserAsync only change the shared DbContext. The caller saves,
        // so a login, refresh or password change is stored in one SaveChanges.
        public void Add(RefreshTokens refreshToken)
        {
            _refreshTokens.Add(refreshToken);
        }

        public async Task RemoveAllForUserAsync(Guid userId)
        {
            var tokens = await _refreshTokens.Where(rt => rt.UserUUID == userId).ToListAsync();
            _refreshTokens.RemoveRange(tokens);
        }
    }
}
