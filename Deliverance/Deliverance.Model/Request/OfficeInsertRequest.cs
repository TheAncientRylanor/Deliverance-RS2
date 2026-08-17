using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Deliverance.Model.Request
{
    public class OfficeInsertRequest
    {
        public string Name { get; set; } = string.Empty;
        public List<DeviceInsertRequest>? Devices {get;set;}
    }
}
