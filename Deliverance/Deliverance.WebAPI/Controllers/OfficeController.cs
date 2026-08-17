using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services;

namespace Deliverance.WebAPI.Controllers
{
    public class OfficeController : BaseCRUDController<OfficeResponse, OfficeSearchObject,
        OfficeInsertRequest, OfficeUpdateRequest,IOfficeService>
    {
        public OfficeController(IOfficeService officeService) : base(officeService)
        {

        }
    }
}
