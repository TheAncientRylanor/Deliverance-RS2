using Deliverance.Model.RabbitMessages;
using Deliverance.Model.Enums;
using Deliverance.Model.Exceptions;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services.Database;
using Deliverance.Services.Messaging;
using Deliverance.Services.ReportStateMachine;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace Deliverance.Services
{
    public class ReportService : BaseCRUDService<Report, ReportResponse, ReportSearchObject
        , ReportInsertRequest, ReportUpdateRequest>, IReportService
    {
        private readonly BaseReportState _reportState;
        private readonly IReportEventPublisher _reportEventPublisher;
        private readonly IValidator<ReportClearRequest> _clearValidator;
        private readonly INotificationService _notificationService;

        public ReportService(DeliveranceDbContext dbContext, IMapper mapper,
            IValidator<ReportInsertRequest> insertValidator, IValidator<ReportUpdateRequest> updateValidator,
            IValidator<ReportClearRequest> clearValidator,
            BaseReportState reportState, IReportEventPublisher reportEventPublisher,
            INotificationService notificationService)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
            _reportState = reportState;
            _reportEventPublisher = reportEventPublisher;
            _clearValidator = clearValidator;
            _notificationService = notificationService;
        }

        protected override Report MapInsertRequestToEntity(ReportInsertRequest request)
        {
            var entity = base.MapInsertRequestToEntity(request);

            entity.Status = request.IsDraft ? nameof(DraftReportState) : nameof(UnseenReportState);

            entity.OfficeReports = request.OfficeReports?
                .Select(officeReportRequest => new OfficeReport
                {
                    OfficeId = officeReportRequest.OfficeId,
                    NumReportedDevices = officeReportRequest.DeviceReports?.Count ?? 0,
                    DeviceReports = officeReportRequest.DeviceReports?
                        .Select(deviceReportRequest => new DeviceReport
                        {
                            Occurrence = deviceReportRequest.Occurrence,
                            Detail = deviceReportRequest.Detail,
                            DeviceId = deviceReportRequest.DeviceId,
                        })
                        .ToList() ?? new List<DeviceReport>()
                })
                .ToList() ?? new List<OfficeReport>();

            entity.ReportOccurrences = request.ReportOccurrences?
                .Where(reportOccurrenceRequest => reportOccurrenceRequest.Answer != null)
                .Select(reportOccurrenceRequest => new ReportOccurrence
                {
                    OccurrenceId = reportOccurrenceRequest.OccurrenceId,
                    Answer = reportOccurrenceRequest.Answer!.Value,
                })
                .ToList() ?? new List<ReportOccurrence>();

            return entity;
        }


        protected override IQueryable<Report> ApplyFilters(IQueryable<Report> query, ReportSearchObject? search, Guid userId, bool isAdmin = false)
        {
            if (!isAdmin)
            {
                query = query.Where(x => x.UserUUID == userId);
            }
            else
            {
                query = query.Where(x => x.Status != nameof(StatusEnum.DraftReportState));
            }

            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.ReportName))
                {
                    query = query.Where(x => x.ReportName.Contains(search.ReportName));
                }
                if (search.OfficeId != null)
                {
                    query = query.Where(x => x.OfficeReports.Any(officeReport =>
                        officeReport.OfficeId == search.OfficeId
                        && (search.DeviceId == null || officeReport.DeviceReports.Any(deviceReport => deviceReport.DeviceId == search.DeviceId))));
                }
                else if (search.DeviceId != null)
                {
                    query = query.Where(x => x.OfficeReports.Any(officeReport =>
                        officeReport.DeviceReports.Any(deviceReport => deviceReport.DeviceId == search.DeviceId)));
                }
                if (search.UserId != null && Guid.TryParse(search.UserId, out Guid id))
                {

                    query = query.Where(x => x.UserUUID == id);
                }
                if (search.Status != null)
                {
                    query = search.Status switch
                    {
                        ReportStatusFilter.Draft => query.Where(x => x.Status == nameof(StatusEnum.DraftReportState)),
                        ReportStatusFilter.Cleared => query.Where(x => x.Status == nameof(StatusEnum.ClearedReportState)),
                        ReportStatusFilter.Active => query.Where(x => x.Status == nameof(StatusEnum.SeenReportState) || x.Status == nameof(StatusEnum.UnseenReportState)),
                        _ => query
                    };
                }
            }
            return query;
        }
        public override async Task<ReportResponse> GetByIdAsync(int id, Guid userId, bool isAdmin = false)
        {
            var entity = await GetQuery()
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.Id == id);
            if (entity == null)
            {
                throw new NotFoundException($"{typeof(Report).Name} with id {id} was not found.");
            }
            if (!isAdmin && entity.UserUUID != userId)
            {
                throw new ForbiddenException("You do not have access to this report.");
            }

            return _mapper.Map<ReportResponse>(entity);
        }

        public override IQueryable<Report> GetQuery()
        {
            return this._dbContext.Set<Report>()
            .Include(x => x.ReportOccurrences)
                .ThenInclude(x => x.Occurrence)
                .Include(x => x.OfficeReports)
                    .ThenInclude(x => x.DeviceReports)
                    .ThenInclude(x => x.Device)
                .Include(x => x.OfficeReports)
                    .ThenInclude(x => x.Office)
                .Include(x => x.User)
                .AsSplitQuery();
        }

        public override async Task<ReportResponse> InsertAsync(ReportInsertRequest request, Guid userId)
        {
            await _insertValidator.ValidateAndThrowAsync(request);
            await EnsureReportCanBeSavedAsync(
                request.OfficeReports.Select(o => (o.OfficeId, o.DeviceReports.Select(d => d.DeviceId))),
                request.ReportOccurrences.Where(o => o.Answer != null).Select(o => o.OccurrenceId),
                isSending: !request.IsDraft, userId, reportId: null);

            var (inserted, notifications) = await _dbContext.InTransactionAsync(async () =>
            {
                var inserted = await base.InsertAsync(request, userId);
                var notifications = request.IsDraft
                    ? NoNotifications
                    : await AddReportSentNotificationsAsync(inserted, userId);
                await _dbContext.SaveChangesAsync();
                return (inserted, notifications);
            });

            await _notificationService.PushAsync(notifications);
            await _reportEventPublisher.PublishAsync(new ReportChangedMessage { ReportId = inserted.Id, Type = ChangeType.Created });
            return await GetByIdAsync(inserted.Id, userId);
        }

        public override async Task<ReportResponse> UpdateAsync(int id, ReportUpdateRequest request, Guid userId, bool isAdmin = false)
        {
            var entity = await EnsureOwnedEntityAsync(id, userId, isAdmin: false);
            var status = entity.Status ?? nameof(DraftReportState);
            var state = _reportState.GetReportState(status);

            if (status is nameof(DraftReportState) or nameof(UnseenReportState))
            {
                await _updateValidator.ValidateAndThrowAsync(request);
                await EnsureReportCanBeSavedAsync(
                    request.OfficeReports.Select(o => (o.OfficeId, o.DeviceReports.Select(d => d.DeviceId))),
                    request.ReportOccurrences.Where(o => o.Answer != null).Select(o => o.OccurrenceId),
                    isSending: !request.IsDraft, entity.UserUUID, reportId: id);
            }

            var (result, notifications) = await _dbContext.InTransactionAsync(async () =>
            {
                var result = await state.UpdateAsync(id, request);
                var notifications = status == nameof(DraftReportState) && !request.IsDraft
                    ? await AddReportSentNotificationsAsync(result, userId)
                    : NoNotifications;
                await _dbContext.SaveChangesAsync();
                return (result, notifications);
            });

            await _notificationService.PushAsync(notifications);
            await _reportEventPublisher.PublishAsync(new ReportChangedMessage { ReportId = id, Type = ChangeType.Updated });
            return await GetByIdAsync(id, userId, isAdmin);
        }

        public override async Task DeleteAsync(int id, Guid userId, bool isAdmin = false)
        {
            var entity = await EnsureOwnedEntityAsync(id, userId, isAdmin: false);
            var state = _reportState.GetReportState(entity.Status ?? nameof(DraftReportState));
            await state.DeleteAsync(id);
            await _reportEventPublisher.PublishAsync(new ReportChangedMessage { ReportId = id, Type = ChangeType.Removed });
        }

        public async Task<ReportResponse> SeenAsync(int id, Guid userId, bool isAdmin = false)
        {
            var entity = await EnsureOwnedEntityAsync(id, userId, isAdmin);
            var state = _reportState.GetReportState(entity.Status ?? nameof(DraftReportState));
            var (result, notifications) = await _dbContext.InTransactionAsync(async () =>
            {
                var result = await state.SeenAsync(id, isAdmin);
                var notifications = await AddOwnerNotificationAsync(entity, userId, NotificationTypeEnum.ReportSeen,
                    "Report seen", $"An admin has seen your report \"{result.ReportName}\".");
                await _dbContext.SaveChangesAsync();
                return (result, notifications);
            });

            await _notificationService.PushAsync(notifications);
            return await GetByIdAsync(id, userId, isAdmin);
        }

        public async Task<ReportResponse> ClearAsync(int id, ReportClearRequest request, Guid userId, bool isAdmin = false)
        {
            await _clearValidator.ValidateAndThrowAsync(request);
            var entity = await EnsureOwnedEntityAsync(id, userId, isAdmin);
            var state = _reportState.GetReportState(entity.Status ?? nameof(DraftReportState));
            var (result, notifications) = await _dbContext.InTransactionAsync(async () =>
            {
                var result = await state.ClearAsync(id, request, userId, isAdmin);
                var notifications = await AddOwnerNotificationAsync(entity, userId, NotificationTypeEnum.ReportCleared,
                    "Report cleared", $"Your report \"{result.ReportName}\" has been cleared.");
                await _dbContext.SaveChangesAsync();
                return (result, notifications);
            });

            await _notificationService.PushAsync(notifications);
            await _reportEventPublisher.PublishAsync(new ReportChangedMessage { ReportId = id, Type = ChangeType.Updated });
            return await GetByIdAsync(id, userId, isAdmin);
        }

        private async Task EnsureReportCanBeSavedAsync(
            IEnumerable<(int OfficeId, IEnumerable<int> DeviceIds)> officeReports,
            IEnumerable<int> answeredOccurrenceIds, bool isSending, Guid ownerId, int? reportId)
        {
            var offices = officeReports.Select(o => (o.OfficeId, DeviceIds: o.DeviceIds.ToList())).ToList();
            var officeIds = offices.Select(o => o.OfficeId).Distinct().ToList();
            var deviceIds = offices.SelectMany(o => o.DeviceIds).Distinct().ToList();
            var occurrenceIds = answeredOccurrenceIds.Distinct().ToList();

            var existingOfficeCount = await _dbContext.Offices.CountAsync(o => officeIds.Contains(o.Id));
            if (existingOfficeCount != officeIds.Count)
            {
                throw new BusinessException("One of the selected offices no longer exists. Reload the offices and choose again.");
            }

            var devices = await _dbContext.Devices
                .Where(d => deviceIds.Contains(d.Id))
                .Select(d => new { d.Id, d.Name, d.OfficeId })
                .ToDictionaryAsync(d => d.Id);
            if (devices.Count != deviceIds.Count)
            {
                throw new BusinessException("One of the selected devices no longer exists. Reload the office and choose again.");
            }
            foreach (var (officeId, officeDeviceIds) in offices)
            {
                var misplaced = officeDeviceIds.Select(id => devices[id]).FirstOrDefault(d => d.OfficeId != officeId);
                if (misplaced != null)
                {
                    throw new BusinessException($"{misplaced.Name} is not in the office it was reported under. Pick it from its own office.");
                }
            }

            var existingOccurrenceCount = await _dbContext.Occurrences.CountAsync(o => occurrenceIds.Contains(o.Id));
            if (existingOccurrenceCount != occurrenceIds.Count)
            {
                throw new BusinessException("One of the answered questions no longer exists. Reload the report and answer again.");
            }

            if (isSending && deviceIds.Count > 0)
            {
                var duplicate = await _dbContext.DeviceReports
                    .Where(dr => deviceIds.Contains(dr.DeviceId)
                        && dr.OfficeReport!.Report!.UserUUID == ownerId
                        && dr.OfficeReport.ReportId != (reportId ?? 0)
                        && (dr.OfficeReport.Report.Status == nameof(UnseenReportState)
                            || dr.OfficeReport.Report.Status == nameof(SeenReportState)))
                    .Select(dr => new { DeviceName = dr.Device!.Name, dr.OfficeReport!.Report!.ReportName })
                    .FirstOrDefaultAsync();
                if (duplicate != null)
                {
                    throw new BusinessException(
                        $"You already have an open report about {duplicate.DeviceName} (\"{duplicate.ReportName}\"). " +
                        "Wait until it is cleared, or save this one as a draft.");
                }
            }
        }

        private static readonly IReadOnlyList<Notification> NoNotifications = Array.Empty<Notification>();

        private Task<IReadOnlyList<Notification>> AddReportSentNotificationsAsync(ReportResponse report, Guid senderId)
            => _notificationService.AddForAdminsAsync(NotificationTypeEnum.ReportSent, "New report",
                $"\"{report.ReportName}\" was sent.", report.Id, senderId);

        private Task<IReadOnlyList<Notification>> AddOwnerNotificationAsync(Report report, Guid actorId,
            NotificationTypeEnum type, string title, string text)
            => report.UserUUID == actorId
                ? Task.FromResult(NoNotifications)
                : _notificationService.AddForUserAsync(report.UserUUID, type, title, text, report.Id);

        private async Task<Report> EnsureOwnedEntityAsync(int id, Guid userId, bool isAdmin)
        {
            var entity = await this._dbContext.Set<Report>().FindAsync(id);
            if (entity == null)
            {
                throw new NotFoundException($"{typeof(Report).Name} with id {id} was not found.");
            }
            if (!isAdmin && entity.UserUUID != userId)
            {
                throw new ForbiddenException("You do not have access to this report.");
            }

            return entity;
        }
    }
}
