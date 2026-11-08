using Deliverance.Model.Exceptions;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace Deliverance.Services.ReportStateMachine;

public class BaseReportState
{
    public BaseReportState(DeliveranceDbContext dbContext, IMapper mapper, IServiceProvider serviceProvider)
    {
        DbContext = dbContext;
        Mapper = mapper;
        ServiceProvider = serviceProvider;
    }

    protected DeliveranceDbContext DbContext { get; }
    protected IMapper Mapper { get; }
    protected IServiceProvider ServiceProvider { get; }

    public virtual Task<ReportResponse> UpdateAsync(int id, ReportUpdateRequest request)
        => throw new BusinessException("This report can't be edited anymore.");

    public virtual Task<ReportResponse> SeenAsync(int id, bool isAdmin = false)
        => throw new BusinessException("Only a sent report that no admin has seen yet can be marked as seen.");

    public virtual Task<ReportResponse> ClearAsync(int id, ReportClearRequest request, Guid adminId, bool isAdmin = false)
        => throw new BusinessException("Only a report an admin has seen can be cleared.");

    public virtual Task DeleteAsync(int id)
        => throw new BusinessException("Only draft reports can be deleted. This report has already been sent.");

    public BaseReportState GetReportState(string stateName) => stateName switch
    {
        nameof(DraftReportState) => ServiceProvider.GetRequiredService<DraftReportState>(),
        nameof(UnseenReportState) => ServiceProvider.GetRequiredService<UnseenReportState>(),
        nameof(SeenReportState) => ServiceProvider.GetRequiredService<SeenReportState>(),
        nameof(ClearedReportState) => ServiceProvider.GetRequiredService<ClearedReportState>(),
        _ => throw new InvalidOperationException($"Unknown report state: {stateName}"),
    };

    protected async Task<Report> LoadReportAsync(int id)
        => await DbContext.Reports
               .Include(x => x.OfficeReports)
                   .ThenInclude(x => x.DeviceReports)
                   .ThenInclude(x => x.Device)
               .Include(x => x.ReportOccurrences)
                   .ThenInclude(x => x.Occurrence)
               .FirstOrDefaultAsync(x => x.Id == id)
           ?? throw new NotFoundException($"Report with id {id} was not found.");

    protected async Task<ReportResponse> ApplyUpdateAsync(int id, ReportUpdateRequest request, string status)
    {
        var entity = await LoadReportAsync(id);
        Mapper.Map(request, entity);

        CollectionSync.Sync(
            entity.OfficeReports,
            request.OfficeReports,
            officeReport => officeReport.Id.ToString(),
            officeReportRequest => officeReportRequest.Id.ToString() ?? string.Empty,
            officeReportRequest => new OfficeReport
            {
                ReportId = entity.Id,
                OfficeId = officeReportRequest.OfficeId,
                NumReportedDevices = officeReportRequest.DeviceReports.Count,
                DeviceReports = officeReportRequest.DeviceReports
                    .Select(deviceReportRequest => new DeviceReport
                    {
                        Occurrence = deviceReportRequest.Occurrence,
                        Detail = deviceReportRequest.Detail,
                        DeviceId = deviceReportRequest.DeviceId,
                    })
                    .ToList(),
            },
            (existingOfficeReport, officeReportRequest) =>
            {
                existingOfficeReport.OfficeId = officeReportRequest.OfficeId;
                existingOfficeReport.NumReportedDevices = officeReportRequest.DeviceReports.Count;

                CollectionSync.Sync(
                    existingOfficeReport.DeviceReports,
                    officeReportRequest.DeviceReports,
                    deviceReport => deviceReport.Id.ToString(),
                    deviceReportRequest => deviceReportRequest.Id.ToString() ?? string.Empty,
                    deviceReportRequest => new DeviceReport
                    {
                        OfficeReportId = existingOfficeReport.Id,
                        Occurrence = deviceReportRequest.Occurrence,
                        Detail = deviceReportRequest.Detail,
                        DeviceId = deviceReportRequest.DeviceId,
                    },
                    (existingDeviceReport, deviceReportRequest) =>
                    {
                        existingDeviceReport.Occurrence = deviceReportRequest.Occurrence;
                        existingDeviceReport.Detail = deviceReportRequest.Detail;
                        existingDeviceReport.DeviceId = deviceReportRequest.DeviceId;
                    });
            });

        CollectionSync.Sync(
            entity.ReportOccurrences,
            request.ReportOccurrences.Where(answer => answer.Answer != null),
            reportOccurrence => reportOccurrence.OccurrenceId.ToString(),
            answer => answer.OccurrenceId.ToString(),
            answer => new ReportOccurrence
            {
                ReportId = entity.Id,
                OccurrenceId = answer.OccurrenceId,
                Answer = answer.Answer!.Value,
            },
            (existingAnswer, answer) => existingAnswer.Answer = answer.Answer!.Value);

        entity.Status = status;
        await DbContext.SaveChangesAsync();
        return Mapper.Map<ReportResponse>(entity);
    }
}
