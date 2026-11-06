using Deliverance.Model.Enums;
using Deliverance.Model.Responses;

namespace Deliverance.Services
{
    public record ReportPoint(int DeviceId, DateTime Date, SeverityEnum? Severity, IssueEnum? IssueType,
        bool IsCleared, DateTime? DateCleared);
    public record LogPoint(int DeviceId, DateTime Date, string? Text);
    public interface IDeviceRecommendationService
    {

        Task<(List<ReportPoint>, List<LogPoint>)> LoadHistoryAsync(int? deviceId = null);
        Task<RecommendationTrainingResponse> TrainAsync(bool isAdmin);
        Task<List<DeviceRecommendationResponse>> GetRecommendationsAsync(int top, int minReports, float minProbability, bool isAdmin);
        Task<DeviceEvidenceResponse> GetDeviceEvidenceAsync(int deviceId, bool isAdmin);
    }
}