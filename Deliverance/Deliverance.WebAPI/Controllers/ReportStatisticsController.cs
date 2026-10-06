using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Deliverance.WebAPI.Controllers
{
    public class ReportStatisticsController : BaseReadController<ReportStatisticsResponse, ReportStatisticsSearchObject, IReportStatisticsService>
    {
        public ReportStatisticsController(IReportStatisticsService reportStatisticsService) : base(reportStatisticsService)
        {
        }
        [Authorize]
        [HttpGet("GetStatistics")]
        public async Task<ReportStatisticsResponse> GetStats([FromQuery]ReportStatisticsSearchObject? search)
    {
        var results = await _service.GetStatistics(search,User.IsAdmin());
        return results;
    }
    }
}
