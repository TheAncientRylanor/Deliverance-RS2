namespace Deliverance.Model.Responses
{
    public class OfficeResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public List<DeviceReportSensitiveResponse>? Devices { get; set; }
        public int? NumOfDevices { get; set; }
        public int? NumOfScouts { get; set; }
    }
}
