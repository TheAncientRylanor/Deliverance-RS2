using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Deliverance.Services.Migrations
{
    /// <inheritdoc />
    public partial class Device3 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "UserUUID",
                table: "Offices",
                type: "UNIQUEIDENTIFIER",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Offices_UserUUID",
                table: "Offices",
                column: "UserUUID");

            migrationBuilder.AddForeignKey(
                name: "FK_Offices_Users_UserUUID",
                table: "Offices",
                column: "UserUUID",
                principalTable: "Users",
                principalColumn: "UUID");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Offices_Users_UserUUID",
                table: "Offices");

            migrationBuilder.DropIndex(
                name: "IX_Offices_UserUUID",
                table: "Offices");

            migrationBuilder.DropColumn(
                name: "UserUUID",
                table: "Offices");
        }
    }
}
