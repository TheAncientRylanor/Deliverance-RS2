using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Deliverance.Services.Migrations
{
    /// <inheritdoc />
    public partial class FixDeviceCreatedAtAndOfficeName : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "CreatedAd",
                table: "Devices",
                newName: "CreatedAt");

            // Devices saved through an office never got these two values. The office's
            // name is the right one; its creation date is the closest known date.
            migrationBuilder.Sql(@"
                UPDATE d
                SET d.OfficeName = o.Name
                FROM Devices d
                INNER JOIN Offices o ON o.Id = d.OfficeId
                WHERE d.OfficeName <> o.Name;

                UPDATE d
                SET d.CreatedAt = o.CreatedAt
                FROM Devices d
                INNER JOIN Offices o ON o.Id = d.OfficeId
                WHERE d.CreatedAt = '0001-01-01';");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "CreatedAt",
                table: "Devices",
                newName: "CreatedAd");
        }
    }
}
