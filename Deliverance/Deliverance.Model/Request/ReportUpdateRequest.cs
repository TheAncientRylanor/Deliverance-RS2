using Deliverance.Model.Enums;

namespace Deliverance.Model.Request
{
    public class ReportUpdateRequest
    {
        public bool IsDraft { get; set; }

        public string ReportName { get; set; } = string.Empty;

        public DateTime DateReported { get; set; }

        public SeverityEnum? Severity { get; set; }
        public IssueEnum? IssueType {get;set;   }

        public string? Detail { get; set; }

        public string? ReportClearedBy { get; set; }

        public ICollection<OfficeReportUpdateRequest> OfficeReports { get; set; } = new List<OfficeReportUpdateRequest>();
        public ICollection<ReportOccuranceUpdate> ReportOccurances { get; set; } = new List<ReportOccuranceUpdate>();
    }
}
