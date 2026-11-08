using Deliverance.Model.Exceptions;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Services.Database;
using Deliverance.Services.ServiceStateMachine;
using FluentValidation;
using MapsterMapper;

public class ClearedReportState : BaseReportState
{
    public ClearedReportState(DeliveranceDbContext dbContext, IMapper mapper,
    
     IServiceProvider serviceProvider,IValidator<ReportInsertRequest> insert,   IValidator<ReportUpdateRequest> update) : 
     base(dbContext, mapper, serviceProvider,insert,update)
    {
    }

    public override Task<ReportResponse> UpdateAsync(int id, ReportUpdateRequest request)
    {
        throw new BusinessException("This report has already been cleared and can't be edited.");
    }
}