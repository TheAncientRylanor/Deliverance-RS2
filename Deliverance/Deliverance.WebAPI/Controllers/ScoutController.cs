using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Deliverance.WebAPI.Controllers
{
    /// <summary>Endpoints called by the scout app, not by users.</summary>
    [ApiController]
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

        // Anonymous: the scout has no account, the enrollment token itself is the proof.
        [AllowAnonymous]
        [HttpPost("Enrollment/Claim")]
        public async Task<ActionResult<ScoutEnrollmentClaimResponse>> ClaimEnrollment([FromBody] ScoutEnrollmentClaimRequest request)
        {
            return await _scoutEnrollmentService.ClaimAsync(request);
        }

        // Anonymous: authenticated by the scout secret in the body. Also used to poll
        // until the admin has saved the device.
        [AllowAnonymous]
        [HttpPost("Auth/Token")]
        public async Task<ActionResult<ScoutTokenResponse>> CreateToken([FromBody] ScoutTokenRequest request)
        {
            return await _scoutAccessManager.CreateTokenAsync(request);
        }

        [Authorize(AuthenticationSchemes = ScoutAuthDefaults.Scheme)]
        [HttpGet("Me")]
        public async Task<ActionResult<ScoutResponse>> GetMe()
        {
            return await _scoutService.GetMeAsync(User.GetScoutId());
        }

        [Authorize(AuthenticationSchemes = ScoutAuthDefaults.Scheme)]
        [HttpPost("Commands/{id}/Result")]
        public async Task<IActionResult> CommandUpdate(int id, [FromBody] ScoutCommandResultRequest result)
        {
            await _scoutService.CommandUpdate(id, result, User.GetScoutId());
            return NoContent();
        }

        [Authorize(AuthenticationSchemes = ScoutAuthDefaults.Scheme)]
        [HttpPost("Logs")]
        public async Task<IActionResult> SaveLogs([FromBody] ScoutLogBatchRequest request)
        {
            await _scoutService.SaveLogsAsync(request, User.GetScoutId());
            return NoContent();
        }
    }
}
