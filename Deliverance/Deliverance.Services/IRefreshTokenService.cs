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
        Task<RefreshTokens?> GetStoredTokenAsync(string refreshToken);
        /// <summary>Adds the token to the shared DbContext. The caller saves.</summary>
        void Add(RefreshTokens refreshToken);
        /// <summary>Marks all of the user's tokens for removal. The caller saves.</summary>
        Task RemoveAllForUserAsync(Guid userId);
    }
}
