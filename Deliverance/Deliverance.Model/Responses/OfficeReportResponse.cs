namespace Deliverance.Model.Responses
{
    public class OfficeReportResponse
    {
        public int Id { get; set; }

        public int ReportId { get; set; }

        public int OfficeId { get; set; }

        public string Name { get; set; } = string.Empty;

        public int? NumReportedDevices { get; set; }
        public ICollection<DeviceReportsResponse> DeviceReports { get; set; } = new List<DeviceReportsResponse>();
    }
}
