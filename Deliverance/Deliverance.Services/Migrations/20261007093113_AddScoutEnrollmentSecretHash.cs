using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Deliverance.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddScoutEnrollmentSecretHash : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "SecretHash",
                table: "ScoutEnrollments",
                type: "nvarchar(64)",
                maxLength: 64,
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_ScoutEnrollments_SecretHash",
                table: "ScoutEnrollments",
                column: "SecretHash",
                unique: true,
                filter: "[SecretHash] IS NOT NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_ScoutEnrollments_SecretHash",
                table: "ScoutEnrollments");

            migrationBuilder.DropColumn(
                name: "SecretHash",
                table: "ScoutEnrollments");
        }
    }
}
