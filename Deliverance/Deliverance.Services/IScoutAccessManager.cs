using Deliverance.Model.Request;
using Deliverance.Model.Responses;

namespace Deliverance.Services
{
    public interface IScoutAccessManager
    {
        Task<ScoutTokenResponse> CreateTokenAsync(ScoutTokenRequest request);
    }
}
