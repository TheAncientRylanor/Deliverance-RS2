using Deliverance.Model.Enums;

namespace Deliverance.Model.Responses
{
    public class DeviceRecommendationResponse
    {
        public int DeviceId { get; set; }
        public string DeviceName { get; set; } = string.Empty;
        public string OfficeName { get; set; } = string.Empty;
        public float NeedsFixProbability { get; set; }
        public IssueEnum LikelyIssue { get; set; }
        public float ReportsLast30Days { get; set; }
    }
}