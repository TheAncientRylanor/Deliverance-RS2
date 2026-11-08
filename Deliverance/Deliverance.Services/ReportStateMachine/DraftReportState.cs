using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Services.Database;
using MapsterMapper;

namespace Deliverance.Services.ReportStateMachine;

public class DraftReportState : BaseReportState
{
    public DraftReportState(DeliveranceDbContext dbContext, IMapper mapper, IServiceProvider serviceProvider)
        : base(dbContext, mapper, serviceProvider)
    {
    }

    public override Task<ReportResponse> UpdateAsync(int id, ReportUpdateRequest request)
        => ApplyUpdateAsync(id, request, request.IsDraft ? nameof(DraftReportState) : nameof(UnseenReportState));

    public override async Task DeleteAsync(int id)
    {
        var entity = await LoadReportAsync(id);
        DbContext.Reports.Remove(entity);
        await DbContext.SaveChangesAsync();
    }
}
