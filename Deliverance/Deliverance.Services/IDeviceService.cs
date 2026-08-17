using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Deliverance.Services
{
    public interface IDeviceService : 
        IBaseCRUDService<DeviceResponse,DeviceSearchObject,DeviceInsertRequest,DeviceUpdateRequest>
    {
        
    }
}
