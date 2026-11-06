namespace Deliverance.Model.Request
{
    /// <summary>
    /// Sent by the scout app: the pasted enrollment token plus the device
    /// information it collected from the PC it runs on.
    /// </summary>
    public class ScoutEnrollmentClaimRequest
    {
        public string Token { get; set; } = string.Empty;
        public string? IpAddress { get; set; }
        public string? MacAddress { get; set; }
        public string? SubnetMask { get; set; }
        public string? VlanID { get; set; }
        public string? OS { get; set; }
        public string? Manufacturer { get; set; }
        public string? Hostname { get; set; }
    }
}
