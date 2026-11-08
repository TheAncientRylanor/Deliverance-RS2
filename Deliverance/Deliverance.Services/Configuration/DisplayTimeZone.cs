namespace Deliverance.Services.Configuration
{
    /// <summary>
    /// Times are stored, compared and sent as UTC. Only where the server itself shows a time
    /// or decides which calendar day/month something falls on (PDFs, statistics per day) is a
    /// time converted, to this zone (DISPLAY_TIME_ZONE in .env). The apps convert on their own.
    /// </summary>
    public sealed class DisplayTimeZone
    {
        public DisplayTimeZone(TimeZoneInfo zone)
        {
            Zone = zone;
        }

        public TimeZoneInfo Zone { get; }

        /// <summary>The current time in the display zone.</summary>
        public DateTime Now => FromUtc(DateTime.UtcNow);

        /// <summary>A UTC time (see <see cref="DateTimeExtensions.AsUtc(DateTime)"/>) as display-zone time.</summary>
        public DateTime FromUtc(DateTime value) => TimeZoneInfo.ConvertTimeFromUtc(value.AsUtc(), Zone);

        public DateTime? FromUtc(DateTime? value) => value is null ? null : FromUtc(value.Value);

        /// <summary>A display-zone wall-clock time, such as the midnight a day starts at, as UTC.</summary>
        public DateTime ToUtc(DateTime displayTime)
            => TimeZoneInfo.ConvertTimeToUtc(DateTime.SpecifyKind(displayTime, DateTimeKind.Unspecified), Zone);
    }
}
