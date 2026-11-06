namespace Deliverance.Model.Responses
{
    /// <summary>The scout installed on a device, as shown on that device.</summary>
    public class DeviceScoutResponse
    {
        public int Id { get; set; }
        public DateTime? CreatedAt { get; set; }
        public bool IsDisabled { get; set; }
    }
}
