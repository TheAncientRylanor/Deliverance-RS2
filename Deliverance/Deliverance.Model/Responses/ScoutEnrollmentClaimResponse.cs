namespace Deliverance.Model.Responses
{
    /// <summary>
    /// The scout's long-term credential. Returned only in the claim response and
    /// stored only as a hash, so the scout must keep it.
    /// </summary>
    public class ScoutEnrollmentClaimResponse
    {
        public string ScoutSecret { get; set; } = string.Empty;
    }
}
