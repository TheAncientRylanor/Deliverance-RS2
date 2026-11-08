using Deliverance.Model.Enums;

namespace Deliverance.Model.Request
{
    public class ScoutCommandInsertRequest
    {
        public int DeviceId { get; set; }
        public ExecutionCommandEnum ExecutionCommandId { get; set; }
        public string CommandText { get; set; } = string.Empty;
    }
}
