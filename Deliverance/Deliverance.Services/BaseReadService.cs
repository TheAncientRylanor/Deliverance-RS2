using Deliverance.Model.SearchObjects;
using Deliverance.Model.Responses;
using Microsoft.EntityFrameworkCore;
using Deliverance.Services.Database;
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

        protected string CompareSortBy(string sortBy)
        {
            var property = _dbContext.Model.FindEntityType(typeof(TEntity))?
                .GetProperties()
                .FirstOrDefault(p => string.Equals(p.Name, sortBy, StringComparison.OrdinalIgnoreCase));
            return property?.Name ?? "";
        }

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

            IQueryable<TEntity> query = GetQuery().AsNoTracking();
            query = ApplyFilters(query, search, userId, isAdmin);

            int? totalCount = null;

            if (search.IncludeTotalCount ?? false)
            {
                totalCount = await query.CountAsync();
            }

            query = ApplySorting(query, search);

            var (page, pageSize) = Paging.Normalize(search.Page, search.PageSize);
            var entities = await query.ToPage(page, pageSize).ToListAsync();
            var list = entities.Select(item => MapToResponse(item, isAdmin)).ToList();

            var pageResult = new PageResult<TResponse>
            {
                Items = list,
                TotalCount = totalCount,
                TotalPages = Paging.TotalPages(totalCount, pageSize),
            };

            return pageResult;
        }

        public virtual async Task<TResponse> GetByIdAsync(int id, Guid userId, bool isAdmin = false)
        {
            var entity = await this._dbContext.Set<TEntity>().FindAsync(id);
            if (entity == null)
            {
                throw new NotFoundException($"{typeof(TEntity).Name} with id {id} was not found.");
            }
            if (!isAdmin && entity is IUserOwnedEntity ownedEntity && userId != Guid.Empty
                && ownedEntity.UserUUID != userId)
            {
                throw new ForbiddenException("You do not have access to this resource.");
            }

            return _mapper.Map<TResponse>(entity);
        }
    }
}
