using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services.Database;
using MapsterMapper;
using Microsoft.Extensions.Caching.Memory;

namespace Deliverance.Services
{
    public class OccurrenceService : BaseReadService<Occurrence, OccurrenceResponse, OccurrenceSearchObject>, IOccurrenceService
    {
        private const string CacheKeyPrefix = "occurrences:";
        private readonly IMemoryCache _cache;

        public OccurrenceService(IMapper mapper, DeliveranceDbContext dbContext, IMemoryCache cache)
        : base(mapper, dbContext)
        {
            _cache = cache;
        }

        public override async Task<PageResult<OccurrenceResponse>> GetAllAsync(OccurrenceSearchObject? search = null,
            Guid userId = default, bool isAdmin = false)
        {
            if (!string.IsNullOrWhiteSpace(search?.Question))
            {
                return await base.GetAllAsync(search, userId, isAdmin);
            }

            var key = $"{CacheKeyPrefix}{search?.Page}:{search?.PageSize}:{search?.SortBy}:{search?.Descending}:{search?.IncludeTotalCount}";
            return (await _cache.GetOrCreateAsync(key, entry =>
            {
                entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(1);
                return base.GetAllAsync(search, userId, isAdmin);
            }))!;
        }

        protected override IQueryable<Occurrence> ApplyFilters(IQueryable<Occurrence> query, OccurrenceSearchObject? search, Guid userId = default, bool isAdmin = false)
        {
            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Question))
                {
                    query = query.Where(p => p.Question.Contains(search.Question));
                }
            }
            return query;
        }
    }
}
