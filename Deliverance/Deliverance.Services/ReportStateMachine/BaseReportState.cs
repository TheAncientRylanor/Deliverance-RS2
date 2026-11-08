using Deliverance.Model.Exceptions;
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
            throw new BusinessException("This report can't be edited anymore.");
        }

        public virtual Task<ReportResponse> SeenAsync(int id, bool isAdmin = false)
        {
            throw new BusinessException("Only a sent report that no admin has seen yet can be marked as seen.");
        }
        public virtual Task<ReportResponse> ClearAsync(int id, ReportClearRequest request, Guid adminId, bool isAdmin = false)
        {
            throw new BusinessException("Only a report an admin has seen can be cleared.");
        }
        public virtual Task DeleteAsync(int id)
        {
            throw new BusinessException("Only draft reports can be deleted. This report has already been sent.");
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