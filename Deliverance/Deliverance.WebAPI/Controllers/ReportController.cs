using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services;

namespace Deliverance.WebAPI.Controllers
{
    public class ReportController : BaseCRUDController<ReportResponse, ReportSearchObject,
        ReportInsertRequest, ReportUpdateRequest, IReportService>
    {
        public ReportController(IReportService reportService) : base(reportService)
        {
        }
    }
}
