using Deliverance.Model.Enums;

namespace Deliverance.Model.Request
{
    public class ScoutCommandResultRequest
    {
        public ScoutCommandStatusEnum Status { get; set; }
        public string? Output { get; set; }
        public int? ExitCode { get; set; }
    }
}
