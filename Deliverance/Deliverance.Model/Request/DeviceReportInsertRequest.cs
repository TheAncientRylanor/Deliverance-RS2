using Deliverance.Model.Enums;

namespace Deliverance.Model.Request
{
    public class DeviceReportInsertRequest
    {
        public string? Occurance { get; set; }

        public string? Detail { get; set; }

        public int DeviceId { get; set; }
    }
}
