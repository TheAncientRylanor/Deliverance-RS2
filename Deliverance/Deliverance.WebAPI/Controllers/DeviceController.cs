using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services;
using Microsoft.AspNetCore.Mvc;

namespace Deliverance.WebAPI.Controllers
{
    public class DeviceController : BaseCRUDController<DeviceResponse, DeviceSearchObject,
        DeviceInsertRequest, DeviceUpdateRequest, IDeviceService>
    {
        public DeviceController(IDeviceService deviceService) : base(deviceService)
        {

        }

        [HttpPut("{id}/Scout/Disable")]
        public async Task<IActionResult> DisableScout(int id)
        {
            await _service.SetScoutDisabledAsync(id, true, User.IsAdmin());
            return NoContent();
        }

        [HttpPut("{id}/Scout/Enable")]
        public async Task<IActionResult> EnableScout(int id)
        {
            await _service.SetScoutDisabledAsync(id, false, User.IsAdmin());
            return NoContent();
        }

        [HttpGet("{id}/Logs")]
        public async Task<PageResult<DeviceEvidenceLogResponse>> GetRecentLogs(int id)
        {
            return await _service.GetRecentLogsAsync(id, User.IsAdmin());
        }

        [HttpPost("{id}/Ping")]
        public async Task<DevicePingResponse> Ping(int id)
        {
            return await _service.PingAsync(id, User.IsAdmin());
        }

        [HttpPost("ScoutCommand")]
        public async Task<ScoutCommandResponse> CommandInsert(ScoutCommandInsertRequest command)
        {
            var result = await _service.SendDeviceCommand(command, User.GetUserId(), User.IsAdmin());
            return result;
        }
    }
}
