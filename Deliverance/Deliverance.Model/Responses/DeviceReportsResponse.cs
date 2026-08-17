using Deliverance.Model.Enums;

namespace Deliverance.Model.Responses
{
    public class DeviceReportsResponse
    {
        public int Id { get; set; }

        public SeverityEnum? Severity { get; set; }

        public string? Detail { get; set; }
        public int OfficeReportId { get; set; }

        public int DeviceId { get; set; }
    }
}
