using Deliverance.Model.Enums;
using Deliverance.Model.Exceptions;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services.Database;
using Deliverance.Services.Messaging;
using Deliverance.Services.ServiceStateMachine;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;

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
                    NumReportedDevices = officeReportRequest.NumReportedDevices,
                    DeviceReports = officeReportRequest.DeviceReports?
                        .Select(deviceReportRequest => new DeviceReport
                        {
                            Occurance = deviceReportRequest.Occurance,
                            Detail = deviceReportRequest.Detail,
                            DeviceId = deviceReportRequest.DeviceId,
                        })
                        .ToList() ?? new List<DeviceReport>()
                })
                .ToList() ?? new List<OfficeReport>();

            entity.ReportOccurances = request.ReportOccurances?
                .Where(reportOccuranceRequest => reportOccuranceRequest.Answer != null)
                .Select(reportOccuranceRequest => new ReportOccurance
                {
                    OccuranceId = reportOccuranceRequest.OccuranceId,
                    Answer = reportOccuranceRequest.Answer!.Value,
                })
                .ToList() ?? new List<ReportOccurance>();

            return entity;
        }

        protected override void MapUpdateRequestToEntity(ReportUpdateRequest request, Report entity)
        {
            base.MapUpdateRequestToEntity(request, entity);

            SyncCollection(
                entity.OfficeReports,
                request.OfficeReports,
                officeReport => officeReport.Id.ToString(),
                officeReportRequest => officeReportRequest.Id.ToString(),
                officeReportRequest => new OfficeReport
                {
                    ReportId = entity.Id,
                    OfficeId = officeReportRequest.OfficeId,
                    NumReportedDevices = officeReportRequest.NumReportedDevices,
                    DeviceReports = officeReportRequest.DeviceReports?
                        .Select(deviceReportRequest => new DeviceReport
                        {
                            Occurance = deviceReportRequest.Occurance,
                            Detail = deviceReportRequest.Detail,
                            DeviceId = deviceReportRequest.DeviceId,
                        })
                        .ToList() ?? new List<DeviceReport>()
                },
                (existingOfficeReport, officeReportRequest) =>
                {
                    existingOfficeReport.OfficeId = officeReportRequest.OfficeId;
                    existingOfficeReport.NumReportedDevices = officeReportRequest.NumReportedDevices;

                    SyncCollection(
                        existingOfficeReport.DeviceReports,
                        officeReportRequest.DeviceReports,
                        deviceReport => deviceReport.Id.ToString(),
                        deviceReportRequest => deviceReportRequest.Id.ToString(),
                        deviceReportRequest => new DeviceReport
                        {
                            OfficeReportId = existingOfficeReport.Id,
                            Occurance = deviceReportRequest.Occurance,
                            Detail = deviceReportRequest.Detail,
                            DeviceId = deviceReportRequest.DeviceId,
                        },
                        (existingDeviceReport, deviceReportRequest) =>
                        {
                            existingDeviceReport.Occurance = deviceReportRequest.Occurance;
                            existingDeviceReport.Detail = deviceReportRequest.Detail;
                            existingDeviceReport.DeviceId = deviceReportRequest.DeviceId;
                        });
                });

            var answeredOccurances = request.ReportOccurances?
                .Where(occuranceUpdateRequest => occuranceUpdateRequest.Answer != null)
                .ToList() ?? new List<ReportOccuranceUpdate>();

            SyncCollection(
                entity.ReportOccurances,
                answeredOccurances,
                reportOccurance => reportOccurance.OccuranceId.ToString(),
                occuranceUpdateRequest => occuranceUpdateRequest.OccuranceId.ToString(),
                occuranceUpdateRequest => new ReportOccurance
                {
                    ReportId = entity.Id,
                    OccuranceId = occuranceUpdateRequest.OccuranceId,
                    Answer = occuranceUpdateRequest.Answer!.Value,
                },
                (existingReportOccurance, occuranceUpdateRequest) =>
                {
                    existingReportOccurance.Answer = occuranceUpdateRequest.Answer!.Value;
                });
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
                throw new NotFoundException($"{typeof(Report).Name} with id {id} not found.");
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
            .Include(x => x.ReportOccurances)
                .ThenInclude(x => x.Occurance)
                .Include(x => x.OfficeReports)
                    .ThenInclude(x => x.DeviceReports)
                    .ThenInclude(x => x.Device)
                .Include(x => x.OfficeReports)
                    .ThenInclude(x => x.Office)
                .Include(x => x.User)
                // One SQL query per included collection instead of a single
                // join that repeats each report once per occurance x device row.
                .AsSplitQuery();
        }

        // The report is saved first (its id is needed for the notifications), then the
        // notifications; the transaction keeps both or neither. Pushes go out after the commit.
        public override async Task<ReportResponse> InsertAsync(ReportInsertRequest request, Guid userId)
        {
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
            var entity = await EnsureOwnedEntityAsync(id, userId, isAdmin);
            // The state changes this same tracked entity, so read the status first.
            var status = entity.Status ?? nameof(DraftReportState);
            var state = _reportState.GetReportState(status);

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
            return result;
        }

        public override async Task DeleteAsync(int id, Guid userId, bool isAdmin = false)
        {
            var entity = await EnsureOwnedEntityAsync(id, userId, isAdmin);
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
            return result;
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
            return result;
        }

        private static readonly IReadOnlyList<Notification> NoNotifications = Array.Empty<Notification>();

        private Task<IReadOnlyList<Notification>> AddReportSentNotificationsAsync(ReportResponse report, Guid senderId)
            => _notificationService.AddForAdminsAsync(NotificationTypeEnum.ReportSent, "New report",
                $"\"{report.ReportName}\" was sent.", report.Id, senderId);

        // Nobody is told about their own action, such as an admin clearing their own report.
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
                throw new NotFoundException($"{typeof(Report).Name} with id {id} not found.");
            }
            if (!isAdmin && entity.UserUUID != userId)
            {
                throw new ForbiddenException("You do not have access to this report.");
            }

            return entity;
        }
    }
}
