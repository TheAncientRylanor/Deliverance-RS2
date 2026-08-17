using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Deliverance.Services.Migrations
{
    /// <inheritdoc />
    public partial class Device : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "IconName",
                table: "Devices",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<double>(
                name: "PositionX",
                table: "Devices",
                type: "float",
                nullable: false,
                defaultValue: 0.0);

            migrationBuilder.AddColumn<double>(
                name: "PositonY",
                table: "Devices",
                type: "float",
                nullable: false,
                defaultValue: 0.0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IconName",
                table: "Devices");

            migrationBuilder.DropColumn(
                name: "PositionX",
                table: "Devices");

            migrationBuilder.DropColumn(
                name: "PositonY",
                table: "Devices");
        }
    }
}
