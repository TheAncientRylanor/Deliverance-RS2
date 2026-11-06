using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Deliverance.Model.Request
{
    public class DeviceUpdateRequest
    {
        public int Id {get;set;}
        public string Name { get; set; } = string.Empty;
        public string? IpAddress { get; set; }
        public string? MacAddress { get; set; }
         public string? SubnetMask {get;set;}
        public string? OfficeName {get;set;}
        public double PositionX {get;set;}
        public double PositionY {get;set;}
        public string IconName {get;set;} = string.Empty;
        public string? Type { get; set; }
        public string? VlanID {get;set;}
        public string? OS {get;set; }    
        public string? Manufacturer { get; set; }
        // Set when the device is a scout enrolled from the device dialog.
        public int? EnrollmentId { get; set; }
    }
}
