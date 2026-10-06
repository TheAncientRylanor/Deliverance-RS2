using Deliverance.Model.Request;
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
}