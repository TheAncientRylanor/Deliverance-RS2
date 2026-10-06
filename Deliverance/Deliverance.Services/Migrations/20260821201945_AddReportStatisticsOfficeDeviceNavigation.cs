using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Deliverance.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddReportStatisticsOfficeDeviceNavigation : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IssueType",
                table: "ReportStatistics");

            migrationBuilder.DropColumn(
                name: "Severity",
                table: "ReportStatistics");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "ReportStatistics");

            migrationBuilder.CreateIndex(
                name: "IX_ReportStatistics_DeviceId",
                table: "ReportStatistics",
                column: "DeviceId");

            migrationBuilder.CreateIndex(
                name: "IX_ReportStatistics_OfficeId",
                table: "ReportStatistics",
                column: "OfficeId");

            migrationBuilder.AddForeignKey(
                name: "FK_ReportStatistics_Devices_DeviceId",
                table: "ReportStatistics",
                column: "DeviceId",
                principalTable: "Devices",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_ReportStatistics_Offices_OfficeId",
                table: "ReportStatistics",
                column: "OfficeId",
                principalTable: "Offices",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ReportStatistics_Devices_DeviceId",
                table: "ReportStatistics");

            migrationBuilder.DropForeignKey(
                name: "FK_ReportStatistics_Offices_OfficeId",
                table: "ReportStatistics");

            migrationBuilder.DropIndex(
                name: "IX_ReportStatistics_DeviceId",
                table: "ReportStatistics");

            migrationBuilder.DropIndex(
                name: "IX_ReportStatistics_OfficeId",
                table: "ReportStatistics");

            migrationBuilder.AddColumn<int>(
                name: "IssueType",
                table: "ReportStatistics",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Severity",
                table: "ReportStatistics",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Status",
                table: "ReportStatistics",
                type: "nvarchar(max)",
                nullable: true);
        }
    }
}
