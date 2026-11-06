using Deliverance.Model.Enums;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services.Database;
using MapsterMapper;

namespace Deliverance.Services
{
    public class ExecutionCommandService : BaseReadService<ExecutionCommand, ExecutionCommandResponse, ExecutionCommandSearchObject>, IExecutionCommandService
    {
        public ExecutionCommandService(IMapper mapper, DeliveranceDbContext dbContext)
        : base(mapper, dbContext)
        {

        }

        protected override IQueryable<ExecutionCommand> ApplyFilters(IQueryable<ExecutionCommand> query, ExecutionCommandSearchObject? search, Guid userId = default, bool isAdmin = false)
        {
            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Name))
                {
                    query = query.Where(p => p.Name.Contains(search.Name));
                }
            }
            return query;
        }

        // The key is an enum, so FindAsync needs the enum value rather than the raw int.
        public override async Task<ExecutionCommandResponse> GetByIdAsync(int id, Guid userId, bool isAdmin = false)
        {
            var entity = await _dbContext.ExecutionCommands.FindAsync((ExecutionCommandEnum)id);
            if (entity == null)
            {
                throw new KeyNotFoundException($"{nameof(ExecutionCommand)} with id {id} not found.");
            }

            return _mapper.Map<ExecutionCommandResponse>(entity);
        }
    }
}
