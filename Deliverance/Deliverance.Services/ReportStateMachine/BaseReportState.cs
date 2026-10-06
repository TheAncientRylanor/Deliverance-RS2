using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.Extensions.DependencyInjection;
namespace Deliverance.Services.ServiceStateMachine
{
    public class BaseReportState
    {
        public BaseReportState(DeliveranceDbContext dbContext, IMapper mapper,
        IServiceProvider serviceProvider, IValidator<ReportInsertRequest> insert,   IValidator<ReportUpdateRequest> update
        )
        {
            DbContext = dbContext;
            Mapper = mapper;
            ServiceProvider = serviceProvider;
            insertValidator = insert;
            updateValidator = update;
        }

        protected DeliveranceDbContext DbContext { get; }
        protected IMapper Mapper { get; }
        protected IServiceProvider ServiceProvider { get; }
        protected IValidator<ReportInsertRequest> insertValidator{get;}
        protected IValidator<ReportUpdateRequest> updateValidator{get;}

        public virtual Task<ReportResponse> UpdateAsync(int id, ReportUpdateRequest request)
        {
            throw new InvalidOperationException("Cannot update a Report in its current state.");
        }

        public virtual Task<ReportResponse> SeenAsync(int id, bool isAdmin = false)
        {
            throw new InvalidOperationException("Cannot activate a Report in its current state.");
        }
        public virtual Task<ReportResponse> ClearAsync(int id, bool isAdmin = false)
        {
            throw new InvalidOperationException("Cannot activate a Report in its current state.");
        }
        public virtual Task DeleteAsync(int id)
        {
            throw new InvalidOperationException("Cannot delete a Report in its current state.");
        }

        public BaseReportState GetReportState(string stateName)
        {
            switch (stateName)
            {
                case nameof(DraftReportState):
                    return ServiceProvider.GetService<DraftReportState>()!;
                case nameof(ClearedReportState):
                    return ServiceProvider.GetService<ClearedReportState>()!;
                case nameof(SeenReportState):
                    return ServiceProvider.GetService<SeenReportState>()!;
                case nameof(UnseenReportState):
                return ServiceProvider.GetService<UnseenReportState>()!;
                default:
                    throw new InvalidOperationException($"Unknown Report state: {stateName}");
            }
        }
         public static void SyncCollection<TItem, TRequest>(
            ICollection<TItem> existingItems,
            IEnumerable<TRequest>? incomingItems,
            Func<TItem, string> getExistingKey,
            Func<TRequest, string> getIncomingKey,
            Func<TRequest, TItem> createItem,
            Action<TItem, TRequest> updateItem)
        {
            if (incomingItems == null)
            {
                return;
            }

            var existingByKey = existingItems.ToDictionary(getExistingKey, StringComparer.OrdinalIgnoreCase);
            var incomingKeys = incomingItems.Select(getIncomingKey).ToHashSet(StringComparer.OrdinalIgnoreCase);

            var toRemove = existingItems
                .Where(item => !incomingKeys.Contains(getExistingKey(item)))
                .ToList();

            foreach (var item in toRemove)
            {
                existingItems.Remove(item);
            }

            foreach (var incomingItem in incomingItems)
            {
                var key = getIncomingKey(incomingItem);

                if (existingByKey.TryGetValue(key, out var existingItem))
                {
                    updateItem(existingItem, incomingItem);
                }
                else
                {
                    existingItems.Add(createItem(incomingItem));
                }
            }
        }
    }
}