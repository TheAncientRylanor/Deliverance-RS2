using Deliverance.Model.Exceptions;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace Deliverance.Services.ReportStateMachine;

public class SeenReportState : BaseReportState
{
    public SeenReportState(DeliveranceDbContext dbContext, IMapper mapper, IServiceProvider serviceProvider)
        : base(dbContext, mapper, serviceProvider)
    {
    }

    public override Task<ReportResponse> UpdateAsync(int id, ReportUpdateRequest request)
        => throw new BusinessException("This report has already been seen by an admin and can't be edited.");

    public override async Task<ReportResponse> ClearAsync(int id, ReportClearRequest request, Guid adminId, bool isAdmin = false)
    {
        if (!isAdmin)
        {
            throw new ForbiddenException("Only an admin can clear a report.");
        }
        var entity = await LoadReportAsync(id);
        entity.Comment = string.IsNullOrWhiteSpace(request.Comment) ? null : request.Comment.Trim();
        if (request.IssueType != null)
        {
            entity.IssueType = request.IssueType;
        }
        entity.Status = nameof(ClearedReportState);
        entity.DateCleared = DateTime.UtcNow;
        entity.ReportClearedBy = await DbContext.Users
            .Where(x => x.UUID == adminId)
            .Select(x => x.Username)
            .FirstOrDefaultAsync();
        await DbContext.SaveChangesAsync();
        return Mapper.Map<ReportResponse>(entity);
    }
}
