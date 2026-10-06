using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Deliverance.Services
{
    public interface IBaseReadService<TResponse, TSearch>
       where TSearch : BaseSearchObject
    {
        Task<TResponse> GetByIdAsync(int id,Guid userId = default, bool isAdmin = false);
        Task<PageResult<TResponse>> GetAllAsync(TSearch? search = null,Guid userId = default, bool isAdmin = false);
    }
}
