using Deliverance.Model.Enums;

namespace Deliverance.Model.Responses
{
    public class ScoutTokenResponse
    {
        public ScoutTokenStatusEnum Status { get; set; }

        public string? AccessToken { get; set; }
        public DateTime? ExpiresAt { get; set; }
    }
}
