using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Deliverance.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddNotificationRelatedUser : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "RelatedUserUUID",
                table: "Notifications",
                type: "uniqueidentifier",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "RelatedUserUUID",
                table: "Notifications");
        }
    }
}
