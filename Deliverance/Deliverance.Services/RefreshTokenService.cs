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

        public async Task InsertAsync(RefreshTokens refreshToken)
        {
            await _context.RefreshTokens.AddAsync(refreshToken);
            await _context.SaveChangesAsync();
        }

        public Task DeleteAllUserRefreshTokensAsync(Guid userId)
        {
            _refreshTokens.RemoveRange(_refreshTokens.Where(rt => rt.UserUUID == userId));
            return _context.SaveChangesAsync();
        }
    }
}
