using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Deliverance.Services
{
    public interface IAccessManager
    {
        Task<UserLoginResponse> LoginAsync(UserLoginRequest request);
        Task<UserLoginResponse> LoginWithRefreshTokenAsync(RefreshAccessTokenRequest request);
    }
}
