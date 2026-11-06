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
        IBaseCRUDService<DeviceResponse, DeviceSearchObject, DeviceInsertRequest, DeviceUpdateRequest>
    {
        /// <summary>Disables or re-enables the scout running on a device (admins only).</summary>
        Task SetScoutDisabledAsync(int deviceId, bool isDisabled, bool isAdmin);

        Task<ScoutCommandResponse> SendDeviceCommand(ScoutCommandInsertRequest command, Guid userId, bool isAdmin);
    }
}
