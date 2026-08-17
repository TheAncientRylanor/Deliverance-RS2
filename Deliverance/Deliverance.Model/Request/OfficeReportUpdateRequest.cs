namespace Deliverance.Model.Request
{
    public class OfficeReportUpdateRequest
    {
        public int Id { get; set; }
        public int OfficeId { get; set; }

        public int? NumReportedDevices { get; set; }
        public ICollection<DeviceReportUpdateRequest> DeviceReports { get; set; } = new List<DeviceReportUpdateRequest>();
    }
}
