
namespace Deliverance.Model.Responses
{
    public class DeviceResponse : DeviceReportSensitiveResponse
    {
        public string? IpAddress { get; set; }
        public string? MacAddress { get; set; }
        public string? SubnetMask { get; set; }
        public string IconName { get; set; } = string.Empty;
        public string? VlanID { get; set; }
        public string? OS { get; set; }
        public bool? IsReported { get; set; }
        public DeviceScoutResponse? Scout { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }
}
