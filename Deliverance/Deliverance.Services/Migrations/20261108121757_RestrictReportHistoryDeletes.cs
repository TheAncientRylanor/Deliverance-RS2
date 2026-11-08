using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Deliverance.Services.Migrations
{
    /// <inheritdoc />
    public partial class RestrictReportHistoryDeletes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_DeviceReports_Devices_DeviceId",
                table: "DeviceReports");

            migrationBuilder.DropForeignKey(
                name: "FK_Offices_Users_UserUUID",
                table: "Offices");

            migrationBuilder.DropForeignKey(
                name: "FK_ReportOccurances_Occurances_OccuranceId",
                table: "ReportOccurances");

            migrationBuilder.DropForeignKey(
                name: "FK_Reports_Users_UserUUID",
                table: "Reports");

            migrationBuilder.DropForeignKey(
                name: "FK_ReportStatistics_Devices_DeviceId",
                table: "ReportStatistics");

            migrationBuilder.AddForeignKey(
                name: "FK_DeviceReports_Devices_DeviceId",
                table: "DeviceReports",
                column: "DeviceId",
                principalTable: "Devices",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Offices_Users_UserUUID",
                table: "Offices",
                column: "UserUUID",
                principalTable: "Users",
                principalColumn: "UUID",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_ReportOccurances_Occurances_OccuranceId",
                table: "ReportOccurances",
                column: "OccuranceId",
                principalTable: "Occurances",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Reports_Users_UserUUID",
                table: "Reports",
                column: "UserUUID",
                principalTable: "Users",
                principalColumn: "UUID",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_ReportStatistics_Devices_DeviceId",
                table: "ReportStatistics",
                column: "DeviceId",
                principalTable: "Devices",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_DeviceReports_Devices_DeviceId",
                table: "DeviceReports");

            migrationBuilder.DropForeignKey(
                name: "FK_Offices_Users_UserUUID",
                table: "Offices");

            migrationBuilder.DropForeignKey(
                name: "FK_ReportOccurances_Occurances_OccuranceId",
                table: "ReportOccurances");

            migrationBuilder.DropForeignKey(
                name: "FK_Reports_Users_UserUUID",
                table: "Reports");

            migrationBuilder.DropForeignKey(
                name: "FK_ReportStatistics_Devices_DeviceId",
                table: "ReportStatistics");

            migrationBuilder.AddForeignKey(
                name: "FK_DeviceReports_Devices_DeviceId",
                table: "DeviceReports",
                column: "DeviceId",
                principalTable: "Devices",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Offices_Users_UserUUID",
                table: "Offices",
                column: "UserUUID",
                principalTable: "Users",
                principalColumn: "UUID",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_ReportOccurances_Occurances_OccuranceId",
                table: "ReportOccurances",
                column: "OccuranceId",
                principalTable: "Occurances",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Reports_Users_UserUUID",
                table: "Reports",
                column: "UserUUID",
                principalTable: "Users",
                principalColumn: "UUID",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_ReportStatistics_Devices_DeviceId",
                table: "ReportStatistics",
                column: "DeviceId",
                principalTable: "Devices",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
