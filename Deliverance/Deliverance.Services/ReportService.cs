using Deliverance.Model.Exceptions;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services.Database;
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
        public ReportService(DeliveranceDbContext dbContext, IMapper mapper,
            IValidator<ReportInsertRequest> insertValidator, IValidator<ReportUpdateRequest> updateValidator)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {

        }

        protected override Report MapInsertRequestToEntity(ReportInsertRequest request)
        {
            var entity = base.MapInsertRequestToEntity(request);

            entity.OfficeReports = request.OfficeReports?
                .Select(officeReportRequest => new OfficeReport
                {
                    OfficeId = officeReportRequest.OfficeId,
                    NumReportedDevices = officeReportRequest.NumReportedDevices,
                    DeviceReports = officeReportRequest.DeviceReports?
                        .Select(deviceReportRequest => new DeviceReport
                        {
                            Severity = deviceReportRequest.Severity,
                            Detail = deviceReportRequest.Detail,
                            DeviceId = deviceReportRequest.DeviceId,
                        })
                        .ToList() ?? new List<DeviceReport>()
                })
                .ToList() ?? new List<OfficeReport>();

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
                            Severity = deviceReportRequest.Severity,
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
                            Severity = deviceReportRequest.Severity,
                            Detail = deviceReportRequest.Detail,
                            DeviceId = deviceReportRequest.DeviceId,
                        },
                        (existingDeviceReport, deviceReportRequest) =>
                        {
                            existingDeviceReport.Severity = deviceReportRequest.Severity;
                            existingDeviceReport.Detail = deviceReportRequest.Detail;
                            existingDeviceReport.DeviceId = deviceReportRequest.DeviceId;
                        });
                });
        }

        protected override IEnumerable<Report> ApplyFilters(IEnumerable<Report> query, ReportSearchObject? search, Guid userId)
        {
            query = query.Where(x => x.UserUUID == userId);

            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.ReportName))
                {
                    query = query.Where(x => x.ReportName.Contains(search.ReportName, StringComparison.OrdinalIgnoreCase));
                }
            }

            return query;
        }

        public override async Task<ReportResponse> GetByIdAsync(int id, Guid userId)
        {
            var entity = this._dbContext.Set<Report>()
                .Include(x => x.OfficeReports)
                    .ThenInclude(x => x.DeviceReports)
                .AsNoTracking().FirstOrDefault(x => x.Id == id);

            if (entity == null)
            {
                throw new KeyNotFoundException($"{typeof(Report).Name} with id {id} not found.");
            }
            if (entity.UserUUID != userId)
            {
                throw new ClientException("You do not have access to this report.");
            }

            return await Task.FromResult(_mapper.Map<ReportResponse>(entity));
        }

        public override IEnumerable<Report> GetQuery()
        {
            return this._dbContext.Set<Report>()
                .Include(x => x.OfficeReports)
                    .ThenInclude(x => x.DeviceReports);
        }
    }
}
