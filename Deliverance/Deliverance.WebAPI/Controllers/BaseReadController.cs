using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Deliverance.WebAPI.Controllers;

/// <summary>
/// Generic base controller for read-only operations (GetAll, GetById)
/// </summary>
/// <typeparam name="TResponse">The response model type</typeparam>
/// <typeparam name="TSearch">The search/filter object type</typeparam>
/// <typeparam name="TService">The service interface type implementing IBaseReadService</typeparam>
[Authorize]
[ApiController]
[Route("[controller]")]
public abstract class BaseReadController<TResponse, TSearch, TService> : ControllerBase
    where TSearch : BaseSearchObject
    where TService : IBaseReadService<TResponse, TSearch>
{
    protected readonly TService _service;

    protected BaseReadController(TService service)
    {
        _service = service;
    }

    [HttpGet]
    public virtual async Task<PageResult<TResponse>> GetAll([FromQuery] TSearch? search)
    {
        var userId = User.GetUserId(); 
        var results = await _service.GetAllAsync(search,userId);
        return results;
    }

    [HttpGet("{id}")]
    public virtual async Task<ActionResult<TResponse>> GetById(int id)
    {
        try
        {
            var userId = User.GetUserId(); 
            var result = await _service.GetByIdAsync(id,userId);
            return Ok(result);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }
}