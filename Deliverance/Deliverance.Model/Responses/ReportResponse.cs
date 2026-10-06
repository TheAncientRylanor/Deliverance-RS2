using Deliverance.Model.Enums;

namespace Deliverance.Model.Responses
{
    public class ReportResponse
    {
        public int Id { get; set; }
        public string ReportName { get; set; } = string.Empty;

        public string? Status { get; set; }
        public DateTime DateReported { get; set; }

        public SeverityEnum? Severity { get; set; }
        public IssueEnum? IssueType {get;set;}

        public string? Detail { get; set; }

        public Guid? UserUUID { get; set; }

        public UserReportResponse? User { get; set; }

        public string? ReportClearedBy { get; set; }

        public ICollection<OfficeReportResponse> OfficeReports { get; set; } = new List<OfficeReportResponse>();
        public ICollection<ReportOccuranceResponse> ReportOccurances { get; set; } = new List<ReportOccuranceResponse>();
    }

     public class UserReportResponse
    {
        public Guid UUID { get; set; }
        public string Username { get; set; } = string.Empty;
        public string? ImagePath {get;set;}
    }
}
