namespace Deliverance.Model.Request
{
    /// <summary>
    /// Sent by the scout app with the Windows events it collected since its last successful send.
    /// </summary>
    public class ScoutLogBatchRequest
    {
        public List<ScoutLogEntryRequest> Logs { get; set; } = new();
    }

    public class ScoutLogEntryRequest
    {
        // Identifies the entry on this scout, so a resent batch isn't saved twice.
        public string EventKey { get; set; } = string.Empty;
        public DateTime DateLogged { get; set; }
        public string Source { get; set; } = string.Empty;
        public int EventId { get; set; }
        // How many identical events the scout merged into this entry.
        public int Count { get; set; } = 1;
        public string Message { get; set; } = string.Empty;
    }
}
