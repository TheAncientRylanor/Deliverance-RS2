using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Deliverance.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddDeviceLastOsUpdate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "LastOsUpdate",
                table: "Devices",
                type: "datetime2",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "LastOsUpdate",
                table: "Devices");
        }
    }
}
