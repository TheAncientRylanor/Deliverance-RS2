using Deliverance.Model.Exceptions;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Services.Database;
using Deliverance.Services.ServiceStateMachine;
using FluentValidation;
using FluentValidation.Results;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

public class UnseenReportState : BaseReportState
{
    public UnseenReportState(DeliveranceDbContext dbContext, IMapper mapper,
    
     IServiceProvider serviceProvider,IValidator<ReportInsertRequest> insert,   IValidator<ReportUpdateRequest> update) : 
     base(dbContext, mapper, serviceProvider,insert,update)
    {
        

    }
    public override async Task<ReportResponse> SeenAsync(int id, bool isAdmin = false)
    {
        var entity = await DbContext.Reports
            .Include(x => x.OfficeReports)
                .ThenInclude(x => x.DeviceReports)
                .ThenInclude(x => x.Device)
            .Include(x => x.ReportOccurances)
                .ThenInclude(x => x.Occurance)
            .FirstOrDefaultAsync(x => x.Id == id);
        if(entity == null)
        {
            throw new ClientException($"Report with {id} not found");
        }
        entity.Status = nameof(SeenReportState);
        await DbContext.SaveChangesAsync();

        return Mapper.Map<ReportResponse>(entity);
    }
    public override async Task<ReportResponse> UpdateAsync(int id, ReportUpdateRequest request)
    {
        var validationResult = await updateValidator.ValidateAsync(request);
        if (validationResult.IsValid == false)
        {
                var errors = validationResult.Errors.Select(e => Mapper.Map<ValidationFailure>(e));
                throw new ValidationException(validationResult.Errors);
        }
        var entity = await DbContext.Reports
            .Include(x => x.OfficeReports)
                .ThenInclude(x => x.DeviceReports)
                .ThenInclude(x => x.Device)
            .Include(x => x.ReportOccurances)
                .ThenInclude(x => x.Occurance)
            .FirstOrDefaultAsync(x => x.Id == id);
        if(entity == null)
        {
            throw new ClientException($"Report with {id} does not exist");
        }
        Mapper.Map(request,entity);
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

              await this.DbContext.SaveChangesAsync();

            return await Task.FromResult(Mapper.Map<ReportResponse>(entity));
    }  
}