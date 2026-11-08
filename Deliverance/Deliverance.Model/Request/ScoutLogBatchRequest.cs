namespace Deliverance.Model.Request
{
    public class ScoutLogBatchRequest
    {
        public List<ScoutLogEntryRequest> Logs { get; set; } = new();
    }

    public class ScoutLogEntryRequest
    {
        public string EventKey { get; set; } = string.Empty;
        public DateTime DateLogged { get; set; }
        public string Source { get; set; } = string.Empty;
        public int EventId { get; set; }
        public int Count { get; set; } = 1;
        public string Message { get; set; } = string.Empty;
    }
}
