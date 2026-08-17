using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Deliverance.WebAPI.Controllers
{
    public class UserController : BaseCRUDController<UserResponse, UserSearchObject,
        UserInsertRequest, UserUpdateRequest,IUserService>
    {
        public UserController(IUserService userService) : base(userService)
        {

        }
    [HttpGet("UUID/{id}")]
    public async Task<ActionResult<UserResponse>> GetByUUID(string id)
    {
        try
        {

            Guid GuidResult = Guid.Parse(id);
            var result = await _service.GetByUUID(GuidResult);
            return Ok(result);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }
    [HttpPut("UpdateUser/{id}")]
    public async Task<ActionResult<UserResponse>> UpdateUser(string id,[FromForm]UserUpdateRequest request)
    {
        try
        {

            Guid GuidResult = Guid.Parse(id);
            var result = await _service.UpdateUserAsync(GuidResult,request);
            return Ok(result);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }
    [AllowAnonymous]
    [HttpPost("InsertUser")]
    public async Task<ActionResult<UserResponse>> InsertUser([FromForm]UserInsertRequest request)
    {
        try
        {
            var result = await _service.InsertAsync(request);
            return Ok(result);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }
    }
}
