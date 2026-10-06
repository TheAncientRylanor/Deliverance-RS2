using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services;

namespace Deliverance.WebAPI.Controllers
{
    public class OccuranceController : BaseReadController<OccuranceResponse, OccuranceSearchObject, IOccuranceService>
    {
        public OccuranceController(IOccuranceService occuranceService) : base(occuranceService)
        {

        }
    }
}
