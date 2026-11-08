using Deliverance.Model.Exceptions;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Services.Database;
using MapsterMapper;

namespace Deliverance.Services.ReportStateMachine;

public class UnseenReportState : BaseReportState
{
    public UnseenReportState(DeliveranceDbContext dbContext, IMapper mapper, IServiceProvider serviceProvider)
        : base(dbContext, mapper, serviceProvider)
    {
    }

    public override async Task<ReportResponse> SeenAsync(int id, bool isAdmin = false)
    {
        if (!isAdmin)
        {
            throw new ForbiddenException("Only an admin can mark a report as seen.");
        }
        var entity = await LoadReportAsync(id);
        entity.Status = nameof(SeenReportState);
        await DbContext.SaveChangesAsync();
        return Mapper.Map<ReportResponse>(entity);
    }

    public override Task<ReportResponse> UpdateAsync(int id, ReportUpdateRequest request)
        => ApplyUpdateAsync(id, request, nameof(UnseenReportState));
}
