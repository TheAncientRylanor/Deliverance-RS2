namespace Deliverance.Model.SearchObjects
{
    public class DeviceSearchObject : BaseSearchObject
    {
        public string? Name { get; set; }
        public string? IpAddress { get; set; }
        public string? MacAddress { get; set; }
        public string? Manufacturer { get; set; }
    }
}
