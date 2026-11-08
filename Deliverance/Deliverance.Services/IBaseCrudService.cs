using Deliverance.Model.SearchObjects;

namespace Deliverance.Services
{
    public interface IBaseCRUDService<TResponse, TSearch, TInsertRequest, TUpdateRequest>
        : IBaseReadService<TResponse, TSearch>
        where TSearch : BaseSearchObject
    {
        Task<TResponse> InsertAsync(TInsertRequest request, Guid userId = default);
        Task<TResponse> UpdateAsync(int id, TUpdateRequest request, Guid userId = default, bool isAdmin = false);
        Task DeleteAsync(int id, Guid userId = default, bool isAdmin = false);
    }
}