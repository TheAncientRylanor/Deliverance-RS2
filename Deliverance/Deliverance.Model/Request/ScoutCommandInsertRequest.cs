using Deliverance.Model.Enums;

namespace Deliverance.Model.Request
{
    /// <summary>
    /// Sent by an admin: the command to run on the scout of <see cref="DeviceId"/>.
    /// </summary>
    public class ScoutCommandInsertRequest
    {
        public int DeviceId { get; set; }
        public ExecutionCommandEnum ExecutionCommandId { get; set; }
        public string CommandText { get; set; } = string.Empty;
    }
}
