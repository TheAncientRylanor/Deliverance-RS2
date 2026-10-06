
namespace Deliverance.Model.Responses
{
    public class DeviceResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? IpAddress { get; set; }
        public string? MacAddress { get; set; }
         public string? SubnetMask {get;set;}
        public double PositionX {get;set;}
        public double PositionY {get;set;}
        public string IconName {get;set;} = string.Empty;
        public string? Type { get; set; }
        public string? VlanID {get;set;}
        public string? OS {get;set; }    
        public string? Manufacturer { get; set; }
        public bool? IsReported {get;set;}
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }
}
