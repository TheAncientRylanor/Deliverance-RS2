using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;

namespace Deliverance.Services
{
    public interface IReportService :
        IBaseCRUDService<ReportResponse, ReportSearchObject, ReportInsertRequest, ReportUpdateRequest>
    {

    }
}
