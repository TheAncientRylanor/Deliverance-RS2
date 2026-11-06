using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Deliverance.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddDeviceLogEventKey : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_DeviceLogs_ScoutId",
                table: "DeviceLogs");

            migrationBuilder.AddColumn<string>(
                name: "EventKey",
                table: "DeviceLogs",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_DeviceLogs_ScoutId_DateLogged",
                table: "DeviceLogs",
                columns: new[] { "ScoutId", "DateLogged" });

            migrationBuilder.CreateIndex(
                name: "IX_DeviceLogs_ScoutId_EventKey",
                table: "DeviceLogs",
                columns: new[] { "ScoutId", "EventKey" },
                unique: true,
                filter: "[EventKey] IS NOT NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_DeviceLogs_ScoutId_DateLogged",
                table: "DeviceLogs");

            migrationBuilder.DropIndex(
                name: "IX_DeviceLogs_ScoutId_EventKey",
                table: "DeviceLogs");

            migrationBuilder.DropColumn(
                name: "EventKey",
                table: "DeviceLogs");

            migrationBuilder.CreateIndex(
                name: "IX_DeviceLogs_ScoutId",
                table: "DeviceLogs",
                column: "ScoutId");
        }
    }
}
