using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;

namespace Deliverance.Services
{
    public interface IBaseReadService<TResponse, TSearch>
       where TSearch : BaseSearchObject
    {
        Task<TResponse> GetByIdAsync(int id, Guid userId = default, bool isAdmin = false);
        Task<PageResult<TResponse>> GetAllAsync(TSearch? search = null, Guid userId = default, bool isAdmin = false);
    }
}
