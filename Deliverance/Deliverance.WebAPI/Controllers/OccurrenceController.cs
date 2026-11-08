using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services;

namespace Deliverance.WebAPI.Controllers
{
    public class OccurrenceController : BaseReadController<OccurrenceResponse, OccurrenceSearchObject, IOccurrenceService>
    {
        public OccurrenceController(IOccurrenceService occurrenceService) : base(occurrenceService)
        {

        }
    }
}
