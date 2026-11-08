using Deliverance.Model.Responses;
using Deliverance.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Deliverance.WebAPI.Controllers
{
    [Authorize]
    [ApiController]
    [Route("[controller]")]
    public class ScoutEnrollmentController : ControllerBase
    {
        private readonly IScoutEnrollmentService _scoutEnrollmentService;

        public ScoutEnrollmentController(IScoutEnrollmentService scoutEnrollmentService)
        {
            _scoutEnrollmentService = scoutEnrollmentService;
        }

        [HttpPost]
        public async Task<ActionResult<ScoutEnrollmentTokenResponse>> Create()
        {
            return await _scoutEnrollmentService.CreateAsync(User.GetUserId(), User.IsAdmin());
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<ScoutEnrollmentResponse>> GetById(int id)
        {
            return await _scoutEnrollmentService.GetByIdAsync(id, User.GetUserId(), User.IsAdmin());
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Cancel(int id)
        {
            await _scoutEnrollmentService.CancelAsync(id, User.GetUserId(), User.IsAdmin());
            return NoContent();
        }
    }
}
