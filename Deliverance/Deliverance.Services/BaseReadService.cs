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
        protected abstract IQueryable<TEntity> ApplyFilters(IQueryable<TEntity> query, TSearch? search, Guid userId = default, bool isAdmin = false);

        /// <summary>
        /// Matches the requested sort column against the entity's mapped columns
        /// (case-insensitive) and returns its exact name, or "" if there is none.
        /// EF.Property needs the exact name, and navigations or unmapped properties
        /// can't be sorted on in SQL.
        /// </summary>
        protected string CompareSortBy(string sortBy)
        {
            var property = _dbContext.Model.FindEntityType(typeof(TEntity))?
                .GetProperties()
                .FirstOrDefault(p => string.Equals(p.Name, sortBy, StringComparison.OrdinalIgnoreCase));
            return property?.Name ?? "";
        }

        /// <summary>
        /// Applies the requested sort, then the primary key as a tie-breaker, so
        /// Skip/Take pages are stable (no overlaps or gaps between pages).
        /// </summary>
        protected IQueryable<TEntity> ApplySorting(IQueryable<TEntity> query, TSearch search)
        {
            IOrderedQueryable<TEntity>? ordered = null;

            if (!string.IsNullOrWhiteSpace(search.SortBy))
            {
                string sortProperty = CompareSortBy(search.SortBy);
                if (!string.IsNullOrEmpty(sortProperty))
                {
                    ordered = search.Descending
                        ? query.OrderByDescending(x => EF.Property<object>(x, sortProperty))
                        : query.OrderBy(x => EF.Property<object>(x, sortProperty));
                }
            }

            var keyProperties = _dbContext.Model.FindEntityType(typeof(TEntity))?
                .FindPrimaryKey()?.Properties.Select(p => p.Name) ?? Enumerable.Empty<string>();
            foreach (var key in keyProperties)
            {
                ordered = ordered == null
                    ? query.OrderBy(x => EF.Property<object>(x, key))
                    : ordered.ThenBy(x => EF.Property<object>(x, key));
            }

            return ordered ?? query;
        }
        /// <summary>
        /// Maps an entity to its response. Override when admins and regular users
        /// should see a different shape of the same resource.
        /// </summary>
        protected virtual TResponse MapToResponse(TEntity entity, bool isAdmin)
        {
            return _mapper.Map<TResponse>(entity);
        }
        public virtual IQueryable<TEntity> GetQuery()
        {
            return this._dbContext.Set<TEntity>();
        }
        public virtual async Task<PageResult<TResponse>> GetAllAsync(TSearch? search = null, Guid userId = default, bool isAdmin = false)
        {
            search ??= (TSearch)Activator.CreateInstance(typeof(TSearch))!;

            // Lists are read-only, so skip change tracking.
            IQueryable<TEntity> query = GetQuery().AsNoTracking();
            query = ApplyFilters(query, search, userId, isAdmin);

            int? totalCount = null;

            if (search.IncludeTotalCount ?? false)
            {
                totalCount = await query.CountAsync();
            }

            query = ApplySorting(query, search);

            if (search.Page.HasValue && search.PageSize.HasValue)
            {
                query = query.Skip((search.Page.Value - 1) * search.PageSize.Value);
            }

            if (search.PageSize.HasValue)
            {
                query = query.Take(search.PageSize.Value);
            }

            var entities = await query.ToListAsync();
            var list = entities.Select(item => MapToResponse(item, isAdmin)).ToList();

            var pageResult = new PageResult<TResponse>
            {
                Items = list,
                TotalCount = totalCount,
                TotalPages = totalCount > 0 && search.PageSize > 0
                    ? (int)Math.Ceiling((double)totalCount.Value / search.PageSize.Value)
                    : null,
            };

            return pageResult;
        }

        public virtual async Task<TResponse> GetByIdAsync(int id, Guid userId, bool isAdmin = false)
        {
            var entity = await this._dbContext.Set<TEntity>().FindAsync(id);
            if (entity == null)
            {
                throw new KeyNotFoundException($"{typeof(TEntity).Name} with id {id} not found.");
            }
            if (!isAdmin && entity is IUserOwnedEntity ownedEntity && userId != Guid.Empty
                && ownedEntity.UserUUID != userId)
            {
                throw new ClientException("You do not have access to this resource.");
            }

            return _mapper.Map<TResponse>(entity);
        }
    }
}
