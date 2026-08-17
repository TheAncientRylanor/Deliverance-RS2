using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Deliverance.Services.Migrations
{
    /// <inheritdoc />
    public partial class Fix : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Scouts_DeviceId",
                table: "Scouts");

            migrationBuilder.CreateIndex(
                name: "IX_Scouts_DeviceId",
                table: "Scouts",
                column: "DeviceId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Scouts_DeviceId",
                table: "Scouts");

            migrationBuilder.CreateIndex(
                name: "IX_Scouts_DeviceId",
                table: "Scouts",
                column: "DeviceId");
        }
    }
}
