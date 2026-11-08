using System.Text.Json.Serialization;

namespace Deliverance.Model.Responses
{
    [JsonDerivedType(typeof(DeviceResponse))]
    public class DeviceReportSensitiveResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Type { get; set; }
        public double PositionX { get; set; }
        public double PositionY { get; set; }
        public string? Manufacturer { get; set; }
    }
}
