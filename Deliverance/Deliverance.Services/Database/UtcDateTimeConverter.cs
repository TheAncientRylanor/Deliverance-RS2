using Microsoft.EntityFrameworkCore.Storage.ValueConversion;

namespace Deliverance.Services.Database
{
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
