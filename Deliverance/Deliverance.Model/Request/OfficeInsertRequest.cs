namespace Deliverance.Model.Request
{
    public class OfficeInsertRequest
    {
        public string Name { get; set; } = string.Empty;
        public List<DeviceInsertRequest>? Devices { get; set; }
    }
}
