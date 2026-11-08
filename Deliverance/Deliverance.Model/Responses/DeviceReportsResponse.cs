namespace Deliverance.Model.Responses
{
    public class DeviceReportsResponse
    {
        public int Id { get; set; }

        public string? Occurrence { get; set; }

        public string? Detail { get; set; }
        public int OfficeReportId { get; set; }

        public int DeviceId { get; set; }
        public string Name { get; set; } = string.Empty;
    }
}
