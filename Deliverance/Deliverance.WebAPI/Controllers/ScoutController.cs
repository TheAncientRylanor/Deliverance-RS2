using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Deliverance.WebAPI.Controllers
{
    [ApiController]
    [Authorize(AuthenticationSchemes = ScoutAuthDefaults.Scheme)]
    [Route("[controller]")]
    public class ScoutController : ControllerBase
    {
        private readonly IScoutEnrollmentService _scoutEnrollmentService;
        private readonly IScoutAccessManager _scoutAccessManager;
        private readonly IScoutService _scoutService;

        public ScoutController(IScoutEnrollmentService scoutEnrollmentService,
            IScoutAccessManager scoutAccessManager, IScoutService scoutService)
        {
            _scoutEnrollmentService = scoutEnrollmentService;
            _scoutAccessManager = scoutAccessManager;
            _scoutService = scoutService;
        }

        [AllowAnonymous]
        [HttpPost("Enrollment/Claim")]
        public async Task<ActionResult<ScoutEnrollmentClaimResponse>> ClaimEnrollment([FromBody] ScoutEnrollmentClaimRequest request)
        {
            return await _scoutEnrollmentService.ClaimAsync(request);
        }

        [AllowAnonymous]
        [HttpPost("Auth/Token")]
        public async Task<ActionResult<ScoutTokenResponse>> CreateToken([FromBody] ScoutTokenRequest request)
        {
            return await _scoutAccessManager.CreateTokenAsync(request);
        }

        [HttpGet("Me")]
        public async Task<ActionResult<ScoutResponse>> GetMe()
        {
            return await _scoutService.GetMeAsync(User.GetScoutId());
        }

        [HttpPost("Commands/{id}/Result")]
        public async Task<IActionResult> CommandUpdate(int id, [FromBody] ScoutCommandResultRequest result)
        {
            await _scoutService.CommandUpdate(id, result, User.GetScoutId());
            return NoContent();
        }

        [HttpPost("Logs")]
        public async Task<IActionResult> SaveLogs([FromBody] ScoutLogBatchRequest request)
        {
            await _scoutService.SaveLogsAsync(request, User.GetScoutId());
            return NoContent();
        }
    }
}
