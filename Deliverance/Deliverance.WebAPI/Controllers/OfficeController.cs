using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services;
using Microsoft.AspNetCore.Mvc;

namespace Deliverance.WebAPI.Controllers
{
    public class OfficeController : BaseCRUDController<OfficeResponse, OfficeSearchObject,
        OfficeInsertRequest, OfficeUpdateRequest,IOfficeService>
    {
        public OfficeController(IOfficeService officeService) : base(officeService)
        {

        }
         [HttpGet("FromReport")]
        public async Task<ActionResult<OfficeResponse>> GetFromReport([FromQuery] int id, [FromQuery] int officeReportId)
        {
            var userId = User.GetUserId();
            var result = await _service.GetFromReport(officeReportId,id, userId, User.IsAdmin());
            return result;
        }
    }
}
