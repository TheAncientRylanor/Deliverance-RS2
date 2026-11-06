using Deliverance.Model.Enums;

namespace Deliverance.Model.Request
{
    /// <summary>
    /// Sent by the scout app once a command finished, failed to start, or timed out.
    /// </summary>
    public class ScoutCommandResultRequest
    {
        public ScoutCommandStatusEnum Status { get; set; }
        public string? Output { get; set; }
        public int? ExitCode { get; set; }
    }
}
