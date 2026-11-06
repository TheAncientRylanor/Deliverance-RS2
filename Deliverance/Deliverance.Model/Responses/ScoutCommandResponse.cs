using Deliverance.Model.Enums;

namespace Deliverance.Model.Responses
{
    /// <summary>A command sent to a scout and its result, as shown in the command history.</summary>
    public class ScoutCommandResponse
    {
        public int Id { get; set; }
        public int ScoutId { get; set; }
        public int DeviceId { get; set; }
        public ExecutionCommandEnum ExecutionCommandId { get; set; }
        public string CommandText { get; set; } = string.Empty;
        public ScoutCommandStatusEnum Status { get; set; }
        public string? Output { get; set; }
        public int? ExitCode { get; set; }
        public Guid? CreatedByUserUUID { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? CompletedAt { get; set; }
    }
}
