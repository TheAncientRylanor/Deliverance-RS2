using Deliverance.Model.Exceptions;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Services.Database;
using MapsterMapper;

namespace Deliverance.Services.ReportStateMachine;

public class ClearedReportState : BaseReportState
{
    public ClearedReportState(DeliveranceDbContext dbContext, IMapper mapper, IServiceProvider serviceProvider)
        : base(dbContext, mapper, serviceProvider)
    {
    }

    public override Task<ReportResponse> UpdateAsync(int id, ReportUpdateRequest request)
        => throw new BusinessException("This report has already been cleared and can't be edited.");
}
