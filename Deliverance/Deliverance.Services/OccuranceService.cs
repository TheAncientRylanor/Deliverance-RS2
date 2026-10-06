using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services.Database;
using MapsterMapper;

namespace Deliverance.Services
{
    public class OccuranceService : BaseReadService<Occurance, OccuranceResponse, OccuranceSearchObject>, IOccuranceService
    {
        public OccuranceService(IMapper mapper, DeliveranceDbContext dbContext)
        : base(mapper, dbContext)
        {

        }

        protected override IQueryable<Occurance> ApplyFilters(IQueryable<Occurance> query, OccuranceSearchObject? search, Guid userId = default, bool isAdmin = false)
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
