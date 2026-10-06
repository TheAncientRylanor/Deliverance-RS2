using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services;
using Microsoft.AspNetCore.Mvc;

namespace Deliverance.WebAPI.Controllers
{
    public class ReportController : BaseCRUDController<ReportResponse, ReportSearchObject,
        ReportInsertRequest, ReportUpdateRequest, IReportService>
    {
        public ReportController(IReportService reportService) : base(reportService)
        {
        }

        [HttpPut("Seen/{id}")]
        public async Task<ActionResult<ReportResponse>> Seen(int id)
        {
            var userId = User.GetUserId();
            var result = await _service.SeenAsync(id, userId, User.IsAdmin());
            return result;
        }

        [HttpPut("Clear/{id}")]
        public async Task<ActionResult<ReportResponse>> Clear(int id)
        {
            var userId = User.GetUserId();
            var result = await _service.ClearAsync(id, userId, User.IsAdmin());
            return result;
        }
    }
}
