using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services;

namespace Deliverance.WebAPI.Controllers
{
    public class DeviceController : BaseCRUDController<DeviceResponse,DeviceSearchObject,
        DeviceInsertRequest,DeviceUpdateRequest,IDeviceService>
    {
        public DeviceController(IDeviceService deviceService): base(deviceService)
        {

        }
    }
}
