using Deliverance.Model.Request;
using Deliverance.Model.Responses;

namespace Deliverance.Services
{
    /// <summary>Operations a scout performs on its own behalf (authenticated as a scout).</summary>
    public interface IScoutService
    {
        Task<ScoutResponse> GetMeAsync(int scoutId);

        Task CommandUpdate(int commandId, ScoutCommandResultRequest result, int scoutId);

        Task SaveLogsAsync(ScoutLogBatchRequest request, int scoutId);
    }
}
