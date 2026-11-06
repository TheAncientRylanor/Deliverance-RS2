using Deliverance.Model.Enums;

namespace Deliverance.Model.Responses
{
    // What an admin sees after opening a device from the recommendations.
    public class DeviceEvidenceResponse
    {
        public DeviceRecommendationResponse Recommendation { get; set; } = new();
        // The lines the model read for this device, newest first. The model scores them
        // together with the reports, so no single line is known to be the cause.
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
