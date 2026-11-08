namespace Deliverance.Services
{
    public static class DateTimeExtensions
    {
        /// <summary>
        /// Every time is stored and sent as UTC. A Local time (for example a query-string value
        /// ending in Z, which ASP.NET parses to server-local) is converted; an Unspecified time
        /// (no zone given) is taken to already be UTC.
        /// </summary>
        public static DateTime AsUtc(this DateTime value) => value.Kind switch
        {
            DateTimeKind.Utc => value,
            DateTimeKind.Local => value.ToUniversalTime(),
            _ => DateTime.SpecifyKind(value, DateTimeKind.Utc),
        };

        public static DateTime? AsUtc(this DateTime? value) => value?.AsUtc();
    }
}
