using Deliverance.Model.Enums;

namespace Deliverance.Model.Request
{
    public class ReportInsertRequest
    {
        public bool IsDraft { get; set; }

        public string ReportName { get; set; } = string.Empty;

        public DateTime DateReported { get; set; }

        public SeverityEnum? Severity { get; set; }
        public IssueEnum? IssueType {get;set;}

        public string? Detail { get; set; }

        public string? ReportClearedBy { get; set; }

        public ICollection<OfficeReportInsertRequest> OfficeReports { get; set; } = new List<OfficeReportInsertRequest>();

        public ICollection<ReportOccuranceInsert> ReportOccurances {get;set;} = new List<ReportOccuranceInsert>();
    }
}
