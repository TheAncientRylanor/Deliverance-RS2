using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Deliverance.WebAPI.Controllers
{
    [ApiController]
    [Authorize]
    [Route("[controller]")]
    public class AccessController : ControllerBase
    {
        private readonly IAccessManager _accessManager;
        private readonly IUserService _userService;

        public AccessController(IAccessManager accessManager, IUserService userService)
        {
            _accessManager = accessManager;
            _userService = userService;
        }

        [AllowAnonymous]
        [HttpPost("Login")]
        public async Task<ActionResult<UserLoginResponse>> Login([FromBody] UserLoginRequest request)
        {
            return await _accessManager.LoginAsync(request);
        }

        [AllowAnonymous]
        [HttpPost("LoginWithRefreshToken")]
        public async Task<ActionResult<UserLoginResponse>> LoginWithRefreshToken([FromBody] RefreshAccessTokenRequest request)
        {
            return await _accessManager.LoginWithRefreshTokenAsync(request);
        }

        [AllowAnonymous]
        [HttpPost("AdminLogin")]
        public async Task<ActionResult<UserLoginResponse>> AdminLogin([FromBody] UserLoginRequest request)
        {
            return await _accessManager.AdminLoginAsync(request);
        }

        [AllowAnonymous]
        [HttpPost("AdminLoginWithRefreshToken")]
        public async Task<ActionResult<UserLoginResponse>> AdminLoginWithRefreshToken([FromBody] RefreshAccessTokenRequest request)
        {
            return await _accessManager.AdminLoginWithRefreshTokenAsync(request);
        }

        [AllowAnonymous]
        [HttpPost("Register")]
        [RequestSizeLimit(ImageService.MaxImageBytes + 1024 * 1024)]
        public async Task<ActionResult<UserResponse>> Register([FromForm] UserInsertRequest request)
        {
            return await _userService.InsertAsync(request);
        }

        [AllowAnonymous]
        [HttpGet("Register/CheckUsername")]
        public async Task<bool> CheckUsername([FromQuery] string username)
        {
            return await _userService.IsUsernameUsed(username ?? string.Empty);
        }

        [HttpPost("ChangePassword")]
        public async Task<IActionResult> ChangePassword([FromBody] UserPasswordChangeRequest request)
        {
            await _accessManager.ChangePasswordAsync(request, User.GetUserId());
            return Ok();
        }

        [HttpPost("Logout")]
        public async Task<IActionResult> Logout()
        {
            await _accessManager.LogoutAsync(User.GetUserId(), User.GetSessionId());
            return NoContent();
        }
    }
}
