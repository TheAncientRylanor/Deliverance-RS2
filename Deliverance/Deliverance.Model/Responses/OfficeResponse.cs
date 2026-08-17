using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Deliverance.Model.Responses
{
    public class OfficeResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public List<DeviceResponse>? Devices {get;set;}
        public int? NumOfDevices { get; set; }
        public int? NumOfScouts { get; set; }
    }
}
