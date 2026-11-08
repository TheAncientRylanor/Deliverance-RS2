using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;

namespace Deliverance.Services
{
    public interface IDeviceService :
        IBaseCRUDService<DeviceResponse, DeviceSearchObject, DeviceInsertRequest, DeviceUpdateRequest>
    {
        Task SetScoutDisabledAsync(int deviceId, bool isDisabled, bool isAdmin);

        Task<PageResult<DeviceEvidenceLogResponse>> GetRecentLogsAsync(int deviceId, bool isAdmin);

        Task<DevicePingResponse> PingAsync(int deviceId, bool isAdmin);

        Task<ScoutCommandResponse> SendDeviceCommand(ScoutCommandInsertRequest command, Guid userId, bool isAdmin);
    }
}
