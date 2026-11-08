using Deliverance.Model.Request;
using Deliverance.Model.Responses;

namespace Deliverance.Services
{
    public interface IScoutService
    {
        Task<ScoutResponse> GetMeAsync(int scoutId);

        Task CommandUpdate(int commandId, ScoutCommandResultRequest result, int scoutId);

        Task SaveLogsAsync(ScoutLogBatchRequest request, int scoutId);

        Task UpdateSystemInfoAsync(ScoutSystemInfoRequest request, int scoutId);
    }
}
