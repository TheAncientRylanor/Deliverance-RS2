using Deliverance.Model.Enums;

namespace Deliverance.Model.Responses
{
    public class DeviceEvidenceResponse
    {
        public DeviceRecommendationResponse Recommendation { get; set; } = new();
        public List<DeviceEvidenceLogResponse> Logs { get; set; } = new();
        public List<DeviceEvidenceReportResponse> Reports { get; set; } = new();
    }

    public class DeviceEvidenceLogResponse
    {
        public DateTime DateLogged { get; set; }
        public string Log { get; set; } = string.Empty;
    }

    public class DeviceEvidenceReportResponse
    {
        public int ReportId { get; set; }
        public string ReportName { get; set; } = string.Empty;
        public DateTime DateReported { get; set; }
        public string? Status { get; set; }
        public SeverityEnum? Severity { get; set; }
        public IssueEnum? IssueType { get; set; }
        public string? Detail { get; set; }
        public string? Comment { get; set; }
    }
}
