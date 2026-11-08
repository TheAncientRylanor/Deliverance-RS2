using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Deliverance.WebAPI.Controllers;

[ApiController]
[Authorize]
[Route("[controller]")]
public class UserController : ControllerBase
{
    private readonly IUserService _service;

    public UserController(IUserService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<PageResult<UserResponse>> GetAll([FromQuery] UserSearchObject? search)
    {
        return await _service.GetAllAsync(search, User.GetUserId(), User.IsAdmin());
    }

    [HttpGet("UUID/{id:guid}")]
    public async Task<ActionResult<UserResponse>> GetByUUID(Guid id)
    {
        return await _service.GetByUUID(id, User.GetUserId(), User.IsAdmin());
    }

    [HttpPut("UpdateUser/{id:guid}")]
    [RequestSizeLimit(ImageService.MaxImageBytes + 1024 * 1024)]
    public async Task<ActionResult<UserResponse>> UpdateUser(Guid id, [FromForm] UserUpdateRequest request)
    {
        return await _service.UpdateUserAsync(id, request, User.GetUserId(), User.IsAdmin());
    }

    [HttpGet("{id:guid}/ProfileImage")]
    public async Task<IActionResult> GetProfileImage(Guid id)
    {
        var (filePath, contentType) = await _service.GetProfileImageAsync(id, User.GetUserId(), User.IsAdmin());
        Response.Headers.CacheControl = "private, max-age=3600";
        Response.Headers.XContentTypeOptions = "nosniff";
        return PhysicalFile(filePath, contentType);
    }
}
