using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace Deliverance.Services.Migrations
{
    /// <inheritdoc />
    public partial class RenameOccurrence : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(name: "FK_ReportOccurances_Occurances_OccuranceId", table: "ReportOccurances");
            migrationBuilder.DropForeignKey(name: "FK_ReportOccurances_Reports_ReportId", table: "ReportOccurances");
            migrationBuilder.DropPrimaryKey(name: "PK_ReportOccurances", table: "ReportOccurances");
            migrationBuilder.DropPrimaryKey(name: "PK_Occurances", table: "Occurances");

            migrationBuilder.RenameTable(name: "Occurances", newName: "Occurrences");
            migrationBuilder.RenameTable(name: "ReportOccurances", newName: "ReportOccurrences");
            migrationBuilder.RenameColumn(name: "OccuranceId", table: "ReportOccurrences", newName: "OccurrenceId");
            migrationBuilder.RenameColumn(name: "Occurance", table: "DeviceReports", newName: "Occurrence");
            migrationBuilder.RenameIndex(name: "IX_ReportOccurances_OccuranceId", table: "ReportOccurrences", newName: "IX_ReportOccurrences_OccurrenceId");
            migrationBuilder.RenameIndex(name: "IX_ReportOccurances_ReportId_OccuranceId", table: "ReportOccurrences", newName: "IX_ReportOccurrences_ReportId_OccurrenceId");

            migrationBuilder.AddPrimaryKey(name: "PK_Occurrences", table: "Occurrences", column: "Id");
            migrationBuilder.AddPrimaryKey(name: "PK_ReportOccurrences", table: "ReportOccurrences", column: "Id");
            migrationBuilder.AddForeignKey(
                name: "FK_ReportOccurrences_Occurrences_OccurrenceId",
                table: "ReportOccurrences",
                column: "OccurrenceId",
                principalTable: "Occurrences",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
            migrationBuilder.AddForeignKey(
                name: "FK_ReportOccurrences_Reports_ReportId",
                table: "ReportOccurrences",
                column: "ReportId",
                principalTable: "Reports",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(name: "FK_ReportOccurrences_Occurrences_OccurrenceId", table: "ReportOccurrences");
            migrationBuilder.DropForeignKey(name: "FK_ReportOccurrences_Reports_ReportId", table: "ReportOccurrences");
            migrationBuilder.DropPrimaryKey(name: "PK_ReportOccurrences", table: "ReportOccurrences");
            migrationBuilder.DropPrimaryKey(name: "PK_Occurrences", table: "Occurrences");

            migrationBuilder.RenameIndex(name: "IX_ReportOccurrences_ReportId_OccurrenceId", table: "ReportOccurrences", newName: "IX_ReportOccurances_ReportId_OccuranceId");
            migrationBuilder.RenameIndex(name: "IX_ReportOccurrences_OccurrenceId", table: "ReportOccurrences", newName: "IX_ReportOccurances_OccuranceId");
            migrationBuilder.RenameColumn(name: "Occurrence", table: "DeviceReports", newName: "Occurance");
            migrationBuilder.RenameColumn(name: "OccurrenceId", table: "ReportOccurrences", newName: "OccuranceId");
            migrationBuilder.RenameTable(name: "ReportOccurrences", newName: "ReportOccurances");
            migrationBuilder.RenameTable(name: "Occurrences", newName: "Occurances");

            migrationBuilder.AddPrimaryKey(name: "PK_Occurances", table: "Occurances", column: "Id");
            migrationBuilder.AddPrimaryKey(name: "PK_ReportOccurances", table: "ReportOccurances", column: "Id");
            migrationBuilder.AddForeignKey(
                name: "FK_ReportOccurances_Occurances_OccuranceId",
                table: "ReportOccurances",
                column: "OccuranceId",
                principalTable: "Occurances",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
            migrationBuilder.AddForeignKey(
                name: "FK_ReportOccurances_Reports_ReportId",
                table: "ReportOccurances",
                column: "ReportId",
                principalTable: "Reports",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
