using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;

namespace Deliverance.Services
{
    public interface IReportStatisticsService :
        IBaseReadService<ReportStatisticsResponse, ReportStatisticsSearchObject>
    {

        Task<ReportStatisticsResponse> GetStatistics(ReportStatisticsSearchObject? search, bool isAdmin = false);
    }
}
