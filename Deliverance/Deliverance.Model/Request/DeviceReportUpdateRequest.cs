using Deliverance.Model.Enums;

namespace Deliverance.Model.Request
{
    public class DeviceReportUpdateRequest
    {
        public int? Id { get; set; }
        public string? Occurance { get; set; }

        public string? Detail { get; set; }

        public int DeviceId { get; set; }
    }
}
