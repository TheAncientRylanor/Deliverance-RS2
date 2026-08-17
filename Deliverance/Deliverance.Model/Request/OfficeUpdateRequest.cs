using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Deliverance.Model.Request
{
    public class OfficeUpdateRequest
    {
        public string Name { get; set; } = string.Empty;
        public List<DeviceUpdateRequest>? Devices {get;set;}
    }
}
