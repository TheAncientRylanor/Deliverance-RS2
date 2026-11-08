using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Deliverance.Services.Migrations
{
    /// <inheritdoc />
    public partial class UniqueReportItemsAndSlots : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_ReportOccurances_ReportId",
                table: "ReportOccurances");

            migrationBuilder.DropIndex(
                name: "IX_OfficeReports_ReportId",
                table: "OfficeReports");

            migrationBuilder.DropIndex(
                name: "IX_DeviceReports_OfficeReportId",
                table: "DeviceReports");

            migrationBuilder.DropIndex(
                name: "IX_Availabilities_ContactId",
                table: "Availabilities");

            migrationBuilder.AlterColumn<string>(
                name: "Day",
                table: "Availabilities",
                type: "nvarchar(10)",
                maxLength: 10,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            // Existing duplicates would block the unique indexes: keep the first row of each
            // (the lowest id) and recount the devices of the office reports that changed.
            migrationBuilder.Sql("""
                WITH Ranked AS (
                    SELECT Id, ROW_NUMBER() OVER (PARTITION BY OfficeReportId, DeviceId ORDER BY Id) AS RowNumber
                    FROM DeviceReports)
                DELETE FROM Ranked WHERE RowNumber > 1;

                WITH Ranked AS (
                    SELECT Id, ROW_NUMBER() OVER (PARTITION BY ReportId, OccuranceId ORDER BY Id) AS RowNumber
                    FROM ReportOccurances)
                DELETE FROM Ranked WHERE RowNumber > 1;

                WITH Ranked AS (
                    SELECT Id, ROW_NUMBER() OVER (PARTITION BY ContactId, Day, FromTime ORDER BY Id) AS RowNumber
                    FROM Availabilities WHERE FromTime IS NOT NULL)
                DELETE FROM Ranked WHERE RowNumber > 1;

                UPDATE o SET NumReportedDevices = (SELECT COUNT(*) FROM DeviceReports d WHERE d.OfficeReportId = o.Id)
                FROM OfficeReports o;
                """);

            migrationBuilder.CreateIndex(
                name: "IX_ReportOccurances_ReportId_OccuranceId",
                table: "ReportOccurances",
                columns: new[] { "ReportId", "OccuranceId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_OfficeReports_ReportId_OfficeId",
                table: "OfficeReports",
                columns: new[] { "ReportId", "OfficeId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_DeviceReports_OfficeReportId_DeviceId",
                table: "DeviceReports",
                columns: new[] { "OfficeReportId", "DeviceId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Availabilities_ContactId_Day_FromTime",
                table: "Availabilities",
                columns: new[] { "ContactId", "Day", "FromTime" },
                unique: true,
                filter: "[FromTime] IS NOT NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_ReportOccurances_ReportId_OccuranceId",
                table: "ReportOccurances");

            migrationBuilder.DropIndex(
                name: "IX_OfficeReports_ReportId_OfficeId",
                table: "OfficeReports");

            migrationBuilder.DropIndex(
                name: "IX_DeviceReports_OfficeReportId_DeviceId",
                table: "DeviceReports");

            migrationBuilder.DropIndex(
                name: "IX_Availabilities_ContactId_Day_FromTime",
                table: "Availabilities");

            migrationBuilder.AlterColumn<string>(
                name: "Day",
                table: "Availabilities",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(10)",
                oldMaxLength: 10);

            migrationBuilder.CreateIndex(
                name: "IX_ReportOccurances_ReportId",
                table: "ReportOccurances",
                column: "ReportId");

            migrationBuilder.CreateIndex(
                name: "IX_OfficeReports_ReportId",
                table: "OfficeReports",
                column: "ReportId");

            migrationBuilder.CreateIndex(
                name: "IX_DeviceReports_OfficeReportId",
                table: "DeviceReports",
                column: "OfficeReportId");

            migrationBuilder.CreateIndex(
                name: "IX_Availabilities_ContactId",
                table: "Availabilities",
                column: "ContactId");
        }
    }
}
