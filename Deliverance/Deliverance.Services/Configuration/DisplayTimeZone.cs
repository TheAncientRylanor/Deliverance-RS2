namespace Deliverance.Services.Configuration
{
    public sealed class DisplayTimeZone
    {
        public DisplayTimeZone(TimeZoneInfo zone)
        {
            Zone = zone;
            SqlServerId = TimeZoneInfo.TryConvertIanaIdToWindowsId(zone.Id, out var windowsId) ? windowsId : zone.Id;
        }

        public TimeZoneInfo Zone { get; }

        public string SqlServerId { get; }

        public DateTime Now => FromUtc(DateTime.UtcNow);

        public DateTime FromUtc(DateTime value) => TimeZoneInfo.ConvertTimeFromUtc(value.AsUtc(), Zone);

        public DateTime? FromUtc(DateTime? value) => value is null ? null : FromUtc(value.Value);

        public DateTime ToUtc(DateTime displayTime)
            => TimeZoneInfo.ConvertTimeToUtc(DateTime.SpecifyKind(displayTime, DateTimeKind.Unspecified), Zone);
    }
}
