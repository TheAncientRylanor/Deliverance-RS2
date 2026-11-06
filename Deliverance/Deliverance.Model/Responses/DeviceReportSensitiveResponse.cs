using System.Text.Json.Serialization;

namespace Deliverance.Model.Responses
{
    /// <summary>
    /// The device fields a regular user needs to pick a device in the mobile
    /// report wizard. Admins get the full <see cref="DeviceResponse"/>.
    /// </summary>
    // Lets a DeviceResponse stored in a DeviceReportSensitiveResponse slot
    // (e.g. OfficeResponse.Devices) serialize with all of its fields.
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
