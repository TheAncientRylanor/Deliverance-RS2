namespace Deliverance.Services.Messaging
{
    public static class RabbitMqConstants
    {
        public const string ReportEventsExchange = "report-events";
        public const string ReportStatisticsQueue = "report-statistics-queue";
        // Messages that still failed after every retry, kept for inspection instead of looping.
        public const string ReportStatisticsFailedQueue = "report-statistics-failed";
    }
}
