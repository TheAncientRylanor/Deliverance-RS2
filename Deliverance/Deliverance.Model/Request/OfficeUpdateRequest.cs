namespace Deliverance.Model.Request
{
    public class OfficeUpdateRequest
    {
        public string Name { get; set; } = string.Empty;
        public List<DeviceUpdateRequest>? Devices { get; set; }
    }
}
