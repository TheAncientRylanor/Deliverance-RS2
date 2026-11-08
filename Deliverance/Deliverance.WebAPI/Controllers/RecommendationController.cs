using Deliverance.Model.Responses;
using Deliverance.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Deliverance.WebAPI.Controllers
{
    [Authorize]
    [ApiController]
    [Route("[controller]")]
    public class RecommendationController : ControllerBase
    {
        private readonly IDeviceRecommendationService _service;

        public RecommendationController(IDeviceRecommendationService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<List<DeviceRecommendationResponse>> Get([FromQuery] int top = 10, [FromQuery] int minReports = 0,
            [FromQuery] float minProbability = 0)
        {
            return await _service.GetRecommendationsAsync(top, minReports, minProbability, User.IsAdmin());
        }

        [HttpGet("{deviceId:int}/Evidence")]
        public async Task<DeviceEvidenceResponse> GetEvidence(int deviceId)
        {
            return await _service.GetDeviceEvidenceAsync(deviceId, User.IsAdmin());
        }

        [HttpGet("Model")]
        public async Task<RecommendationTrainingResponse> GetTrainingInfo()
        {
            return await _service.GetTrainingInfoAsync(User.IsAdmin());
        }

        [HttpPost("Train")]
        public async Task<RecommendationTrainingResponse> Train()
        {
            return await _service.TrainAsync(User.IsAdmin());
        }
    }
}
