using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Deliverance.Services.Migrations
{
    /// <inheritdoc />
    public partial class DeviceNames : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "SubenetMask",
                table: "Devices",
                newName: "SubnetMask");

            migrationBuilder.RenameColumn(
                name: "PositonY",
                table: "Devices",
                newName: "PositionY");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "SubnetMask",
                table: "Devices",
                newName: "SubenetMask");

            migrationBuilder.RenameColumn(
                name: "PositionY",
                table: "Devices",
                newName: "PositonY");
        }
    }
}
