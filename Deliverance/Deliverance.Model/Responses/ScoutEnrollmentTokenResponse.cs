namespace Deliverance.Model.Responses
{
    public class ScoutEnrollmentTokenResponse
    {
        public int EnrollmentId { get; set; }
        public string Token { get; set; } = string.Empty;
        public DateTime ExpiresAt { get; set; }
    }
}
