namespace Deliverance.Model.Request
{
    public class OfficeReportInsertRequest
    {
        public int OfficeId { get; set; }

        public int? NumReportedDevices { get; set; }
        public ICollection<DeviceReportInsertRequest> DeviceReports { get; set; } = new List<DeviceReportInsertRequest>();
    }
}
