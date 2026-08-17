using Deliverance.Model.Enums;

namespace Deliverance.Model.Responses
{
    public class ReportResponse
    {
        public int Id { get; set; }
        public string ReportName { get; set; } = string.Empty;

        public int? Status { get; set; }
        public DateTime DateReported { get; set; }

        public SeverityEnum? Severity { get; set; }

        public string? Detail { get; set; }

        public Guid? UserUUID { get; set; }

        public string? ReportClearedBy { get; set; }

        public ICollection<OfficeReportResponse> OfficeReports { get; set; } = new List<OfficeReportResponse>();
    }
}
