
namespace Deliverance.Services
{
    public class DeviceIssueInput
    {
        public float ReportsLast7Days { get; set; }
        public float ReportsLast30Days { get; set; }
        public float ReportsLast90Days { get; set; }
        public float AvgSeverity { get; set; }
        public float MaxSeverity { get; set; }
        public float PastHardwareIssues { get; set; }
        public float PastSoftwareIssues { get; set; }
        public float DaysSinceLastReport { get; set; }
        public float LogsLast7Days { get; set; }
        public string RecentLogs { get; set; } = string.Empty;

        public string Label { get; set; } = string.Empty;
    }

    public class DeviceIssuePrediction
    {
        public string PredictedLabel { get; set; } = string.Empty;
        public float[] Score { get; set; } = [];
    }

}
