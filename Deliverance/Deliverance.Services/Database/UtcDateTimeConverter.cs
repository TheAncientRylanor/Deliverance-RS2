using Microsoft.EntityFrameworkCore.Storage.ValueConversion;

namespace Deliverance.Services.Database
{
    /// <summary>
    /// Applied to every DateTime column (ConfigureConventions). Writes are normalised to UTC,
    /// and reads come back marked as UTC, so the API's JSON ends in "Z" and clients know the zone.
    /// Query parameters compared with these columns are converted the same way.
    /// </summary>
    public sealed class UtcDateTimeConverter : ValueConverter<DateTime, DateTime>
    {
        public UtcDateTimeConverter()
            : base(
                value => value.AsUtc(),
                value => DateTime.SpecifyKind(value, DateTimeKind.Utc))
        {
        }
    }
}
