using Deliverance.Services.Database;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Deliverance.Services
{
    public interface IRefreshTokenService
    {
        Task<RefreshTokens> GetStoredTokenAsync(string refreshToken);
        Task InsertAsync(RefreshTokens refreshToken);
        Task DeleteAllUserRefreshTokensAsync(Guid userId);
    }
}
