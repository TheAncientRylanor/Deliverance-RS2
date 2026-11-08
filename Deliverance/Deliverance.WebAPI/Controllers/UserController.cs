using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Deliverance.WebAPI.Controllers
{
    public class UserController : BaseCRUDController<UserResponse, UserSearchObject,
        UserInsertRequest, UserUpdateRequest, IUserService>
    {
        public UserController(IUserService userService) : base(userService)
        {

        }

        // Users are keyed by UUID, so the generic int-id endpoints can't work.
        // Use UUID/{id} and UpdateUser/{id} instead.
        [NonAction]
        public override Task<ActionResult<UserResponse>> GetById(int id) => throw new NotSupportedException();

        [NonAction]
        public override Task<ActionResult<UserResponse>> Update(int id, UserUpdateRequest request) => throw new NotSupportedException();

        [NonAction]
        public override Task<IActionResult> Delete(int id) => throw new NotSupportedException();
        // :guid makes a malformed id a 404 instead of a FormatException (500).
        // A missing user throws NotFoundException, which the middleware turns into 404.
        [HttpGet("UUID/{id:guid}")]
        public async Task<ActionResult<UserResponse>> GetByUUID(Guid id)
        {
            var result = await _service.GetByUUID(id, User.GetUserId(), User.IsAdmin());
            return Ok(result);
        }
        [HttpPut("UpdateUser/{id:guid}")]
        public async Task<ActionResult<UserResponse>> UpdateUser(Guid id, [FromForm] UserUpdateRequest request)
        {
            var result = await _service.UpdateUserAsync(id, request, User.GetUserId(), User.IsAdmin());
            return Ok(result);
        }
        [AllowAnonymous]
        [HttpPost("InsertUser")]
        public async Task<ActionResult<UserResponse>> InsertUser([FromForm] UserInsertRequest request)
        {
            var result = await _service.InsertAsync(request);
            return Ok(result);
        }
        [AllowAnonymous]
        [HttpPost("CheckUsername")]
        public async Task<bool> CheckUsername(string request)
        {
            var result = await _service.IsUsernameUsed(request);
            return result;
        }
    }
}
