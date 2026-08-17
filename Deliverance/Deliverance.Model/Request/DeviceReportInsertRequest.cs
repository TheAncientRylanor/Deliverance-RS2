using Deliverance.Model.Enums;

namespace Deliverance.Model.Request
{
    public class DeviceReportInsertRequest
    {
        public SeverityEnum? Severity { get; set; }

        public string? Detail { get; set; }

        public int DeviceId { get; set; }
    }
}
