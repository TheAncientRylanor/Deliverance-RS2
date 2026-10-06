using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Deliverance.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddReportStatisticsFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "IssueType",
                table: "ReportStatistics",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "OfficeId",
                table: "ReportStatistics",
                type: "int",
                nullable: false,
                defaultValue: 0);

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

            migrationBuilder.CreateIndex(
                name: "IX_ReportStatistics_ReportId",
                table: "ReportStatistics",
                column: "ReportId");

            migrationBuilder.AddForeignKey(
                name: "FK_ReportStatistics_Reports_ReportId",
                table: "ReportStatistics",
                column: "ReportId",
                principalTable: "Reports",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ReportStatistics_Reports_ReportId",
                table: "ReportStatistics");

            migrationBuilder.DropIndex(
                name: "IX_ReportStatistics_ReportId",
                table: "ReportStatistics");

            migrationBuilder.DropColumn(
                name: "IssueType",
                table: "ReportStatistics");

            migrationBuilder.DropColumn(
                name: "OfficeId",
                table: "ReportStatistics");

            migrationBuilder.DropColumn(
                name: "Severity",
                table: "ReportStatistics");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "ReportStatistics");
        }
    }
}
