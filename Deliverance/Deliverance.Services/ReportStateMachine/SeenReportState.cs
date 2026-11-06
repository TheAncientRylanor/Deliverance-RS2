using Deliverance.Model.Exceptions;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Services.Database;
using Deliverance.Services.ServiceStateMachine;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

public class SeenReportState : BaseReportState
{
    public SeenReportState(DeliveranceDbContext dbContext, IMapper mapper,
    
     IServiceProvider serviceProvider,IValidator<ReportInsertRequest> insert,   IValidator<ReportUpdateRequest> update) : 
     base(dbContext, mapper, serviceProvider,insert,update)
    {
        
    }

    public override async Task<ReportResponse> ClearAsync(int id, ReportClearRequest request, bool isAdmin = false)
    {
        if (!isAdmin)
        {
            throw new ClientException("Only an admin can clear a Report.");
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
            throw new ClientException($"Report with {id} not found");
        }
        entity.Comment = string.IsNullOrWhiteSpace(request.Comment) ? null : request.Comment.Trim();
        if (request.IssueType != null)
        {
            entity.IssueType = request.IssueType;
        }
        entity.Status = nameof(ClearedReportState);
        entity.DateCleared = DateTime.Now;
        await DbContext.SaveChangesAsync();

        return Mapper.Map<ReportResponse>(entity);
    }
}