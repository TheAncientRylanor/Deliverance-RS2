using Deliverance.Model.Enums;

namespace Deliverance.Model.Request
{
    public class ReportUpdateRequest
    {
        public string ReportName { get; set; } = string.Empty;

        public DateTime DateReported { get; set; }

        public SeverityEnum? Severity { get; set; }

        public string? Detail { get; set; }

        public string? ReportClearedBy { get; set; }

        public ICollection<OfficeReportUpdateRequest> OfficeReports { get; set; } = new List<OfficeReportUpdateRequest>();
    }
}
