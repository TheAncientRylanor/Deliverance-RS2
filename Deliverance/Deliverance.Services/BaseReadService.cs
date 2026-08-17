using Deliverance.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Deliverance.Model.Responses;
using Microsoft.EntityFrameworkCore;
using Deliverance.Services.Database;
using System.Reflection;
using System.Collections;
using Deliverance.Model.Exceptions;

namespace Deliverance.Services
{

    public abstract class BaseReadService<TEntity, TResponse, TSearch> : IBaseReadService<TResponse, TSearch>
        where TEntity : class
        where TSearch : BaseSearchObject
    {
        protected readonly MapsterMapper.IMapper _mapper;
        protected readonly DeliveranceDbContext _dbContext;

        protected BaseReadService(MapsterMapper.IMapper mapper, DeliveranceDbContext dbContext)
        {
            _mapper = mapper;
            _dbContext = dbContext;
        }


        /// <summary>
        /// Applies search filters to the query. Override in derived classes to implement specific filtering logic.
        /// </summary>
        protected abstract IEnumerable<TEntity> ApplyFilters(IEnumerable<TEntity> query, TSearch? search,Guid userId = default);

        protected string CompareSortBy(string sortBy)
        {
            Type entity = typeof(TEntity);
            PropertyInfo[] properties = entity.GetProperties();
            foreach(PropertyInfo prop in properties)
            {
                if(prop.Name.ToLower() == sortBy.ToLower())
                {
                    return sortBy;
                }
            }
            return "";
        }
        public virtual  IEnumerable<TEntity> GetQuery()
        {
            return this._dbContext.Set<TEntity>();
        }
        public virtual async Task<PageResult<TResponse>> GetAllAsync(TSearch? search = null,Guid userId = default)
        {
            IEnumerable<TEntity> query = GetQuery();
            query = ApplyFilters(query, search,userId);

            int? totalCount = null;

            if (search.IncludeTotalCount ?? false)
            {
                totalCount = query.Count();
            }

            if (!string.IsNullOrWhiteSpace(search.SortBy))
            {
                if (search.Descending)
                {
                    query = query.AsQueryable().OrderByDescending(x => EF.Property<object>(x, CompareSortBy(search.SortBy)));
                }
                else
                {
                    query = query.AsQueryable().OrderBy(x => EF.Property<object>(x, CompareSortBy(search.SortBy)));
                }
            }

            if (search.Page.HasValue)
            {
                query = query.Skip((search.Page.Value - 1) * search.PageSize.Value);
            }

            if (search.PageSize.HasValue)
            {
                query = query.Take(search.PageSize.Value);
            }

            var list = query.Select(item => _mapper.Map<TResponse>(item)).ToList();

            var pageResult = new PageResult<TResponse>
            {
                Items = list,
                TotalCount = totalCount
            };

            return await Task.FromResult(pageResult);
        }

        public virtual async Task<TResponse> GetByIdAsync(int id,Guid userId)
        {
            var entity = this._dbContext.Set<TEntity>().Find(id);
            if (entity is IUserOwnedEntity ownedEntity && userId != Guid.Empty)
            {
            if (ownedEntity.UserUUID != userId)
            throw new ClientException("You do not have access to this resource.");
            }
            if (entity == null)
            {
                throw new KeyNotFoundException($"{typeof(TEntity).Name} with id {id} not found.");
            }

            return await Task.FromResult(_mapper.Map<TResponse>(entity));
        }
    }
}
