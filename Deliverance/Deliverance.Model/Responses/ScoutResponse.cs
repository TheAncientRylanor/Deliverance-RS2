namespace Deliverance.Model.Responses
{
    /// <summary>What a scout gets to know about itself.</summary>
    public class ScoutResponse
    {
        public int Id { get; set; }
        public DateTime? CreatedAt { get; set; }
        public int DeviceId { get; set; }
        public string DeviceName { get; set; } = string.Empty;
        public int OfficeId { get; set; }
        public string OfficeName { get; set; } = string.Empty;
    }
}
