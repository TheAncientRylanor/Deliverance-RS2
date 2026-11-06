namespace Deliverance.Model.Responses
{
    /// <summary>
    /// Returned once, when an admin generates a token. The plain token is not
    /// stored on the server, so it can't be fetched again later.
    /// </summary>
    public class ScoutEnrollmentTokenResponse
    {
        public int EnrollmentId { get; set; }
        public string Token { get; set; } = string.Empty;
        public DateTime ExpiresAt { get; set; }
    }
}
