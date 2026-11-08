namespace Deliverance.Model.Request
{
    public class DeviceReportInsertRequest
    {
        public string? Occurrence { get; set; }

        public string? Detail { get; set; }

        public int DeviceId { get; set; }
    }
}
