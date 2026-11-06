using Deliverance.Model.Enums;

namespace Deliverance.Model.Responses
{
    public class ScoutEnrollmentResponse
    {
        public int Id { get; set; }
        public ScoutEnrollmentStatusEnum Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime ExpiresAt { get; set; }
        public DateTime? ClaimedAt { get; set; }
        public string? IpAddress { get; set; }
        public string? MacAddress { get; set; }
        public string? SubnetMask { get; set; }
        public string? VlanID { get; set; }
        public string? OS { get; set; }
        public string? Manufacturer { get; set; }
        public string? Hostname { get; set; }
    }
}
