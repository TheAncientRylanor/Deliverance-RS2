using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Deliverance.Services.Migrations
{
    /// <inheritdoc />
    public partial class UserAndJWT : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_RefreshTokens_Users_UserId",
                table: "RefreshTokens");

            migrationBuilder.DropIndex(
                name: "IX_RefreshTokens_UserId",
                table: "RefreshTokens");

            migrationBuilder.DropColumn(
                name: "UserId",
                table: "RefreshTokens");

            migrationBuilder.AlterColumn<Guid>(
                name: "UUID",
                table: "Users",
                type: "UNIQUEIDENTIFIER",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AddColumn<Guid>(
                name: "UserUUID",
                table: "RefreshTokens",
                type: "UNIQUEIDENTIFIER",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddUniqueConstraint(
                name: "AK_Users_UUID",
                table: "Users",
                column: "UUID");

            migrationBuilder.CreateIndex(
                name: "IX_RefreshTokens_UserUUID",
                table: "RefreshTokens",
                column: "UserUUID",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_RefreshTokens_Users_UserUUID",
                table: "RefreshTokens",
                column: "UserUUID",
                principalTable: "Users",
                principalColumn: "UUID",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_RefreshTokens_Users_UserUUID",
                table: "RefreshTokens");

            migrationBuilder.DropUniqueConstraint(
                name: "AK_Users_UUID",
                table: "Users");

            migrationBuilder.DropIndex(
                name: "IX_RefreshTokens_UserUUID",
                table: "RefreshTokens");

            migrationBuilder.DropColumn(
                name: "UserUUID",
                table: "RefreshTokens");

            migrationBuilder.AlterColumn<string>(
                name: "UUID",
                table: "Users",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(Guid),
                oldType: "UNIQUEIDENTIFIER");

            migrationBuilder.AddColumn<int>(
                name: "UserId",
                table: "RefreshTokens",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateIndex(
                name: "IX_RefreshTokens_UserId",
                table: "RefreshTokens",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_RefreshTokens_Users_UserId",
                table: "RefreshTokens",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
