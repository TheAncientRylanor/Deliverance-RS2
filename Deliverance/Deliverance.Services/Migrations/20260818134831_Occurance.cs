using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Deliverance.Services.Migrations
{
    /// <inheritdoc />
    public partial class Occurance : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Severity",
                table: "DeviceReports");

            migrationBuilder.RenameColumn(
                name: "Issue",
                table: "Reports",
                newName: "IssueType");

            migrationBuilder.AddColumn<string>(
                name: "Occurance",
                table: "DeviceReports",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Occurance",
                table: "DeviceReports");

            migrationBuilder.RenameColumn(
                name: "IssueType",
                table: "Reports",
                newName: "Issue");

            migrationBuilder.AddColumn<int>(
                name: "Severity",
                table: "DeviceReports",
                type: "int",
                nullable: true);
        }
    }
}
