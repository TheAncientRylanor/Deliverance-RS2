using Deliverance.Model.SearchObjects;
using Deliverance.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Deliverance.WebAPI.Controllers;

[ApiController]
[Authorize]
[Route("[controller]")]
public abstract class BaseCRUDController<TResponse, TSearch, TInsertRequest, TUpdateRequest, TService>
    : BaseReadController<TResponse, TSearch, TService>
    where TSearch : BaseSearchObject
    where TService : IBaseCRUDService<TResponse, TSearch, TInsertRequest, TUpdateRequest>
{
    protected BaseCRUDController(TService service) : base(service)
    {
    }

    [HttpPost]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<TResponse>> Create([FromBody] TInsertRequest request)
    {
           var userId = User.GetUserId(); 
        var result = await _service.InsertAsync(request,userId);
        return result;
    }

    [HttpPut("{id}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<TResponse>> Update(int id, [FromBody] TUpdateRequest request)
    {
        var userId = User.GetUserId(); 
        var result = await _service.UpdateAsync(id, request,userId);
        return result;
    }

    [HttpDelete("{id}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int id)
    {
        var userId = User.GetUserId(); 
        await _service.DeleteAsync(id,userId);
        return NoContent();
    }
}