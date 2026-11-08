using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Deliverance.Services.Migrations
{
    /// <summary>
    /// Until now these columns held Sarajevo local time (DateTime.Now, or the phone's local time
    /// for DateReported), while the rest were already UTC. This converts them to UTC so every
    /// column is stored the same way. AT TIME ZONE applies the right offset for summer and winter time.
    /// </summary>
    public partial class ConvertLocalDatesToUtc : Migration
    {
        private const string LocalZone = "Central European Standard Time";

        private static readonly (string Table, string Column)[] LocalColumns =
        {
            ("Reports", "DateReported"),
            ("Reports", "DateCleared"),
            ("ReportStatistics", "DateReported"),
            ("Notifications", "CreatedAt"),
            ("DeviceLogs", "DateLogged"),
        };

        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            foreach (var (table, column) in LocalColumns)
            {
                // Read as local time, then expressed in UTC. NULL stays NULL.
                migrationBuilder.Sql(
                    $"UPDATE [{table}] SET [{column}] = CONVERT(datetime2, ([{column}] AT TIME ZONE '{LocalZone}') AT TIME ZONE 'UTC')");
            }
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            foreach (var (table, column) in LocalColumns)
            {
                migrationBuilder.Sql(
                    $"UPDATE [{table}] SET [{column}] = CONVERT(datetime2, ([{column}] AT TIME ZONE 'UTC') AT TIME ZONE '{LocalZone}')");
            }
        }
    }
}
