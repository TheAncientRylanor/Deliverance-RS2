using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Deliverance.Services.Migrations
{
    /// <inheritdoc />
    public partial class ConversationOwnership : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ChatBotMessages_Users_UserUUID",
                table: "ChatBotMessages");

            migrationBuilder.RenameColumn(
                name: "isFromBot",
                table: "ChatBotMessages",
                newName: "IsFromBot");

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Conversations",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Title",
                table: "Conversations",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "UserUUID",
                table: "Conversations",
                type: "UNIQUEIDENTIFIER",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.CreateIndex(
                name: "IX_Conversations_UserUUID",
                table: "Conversations",
                column: "UserUUID");

            migrationBuilder.AddForeignKey(
                name: "FK_ChatBotMessages_Users_UserUUID",
                table: "ChatBotMessages",
                column: "UserUUID",
                principalTable: "Users",
                principalColumn: "UUID");

            migrationBuilder.AddForeignKey(
                name: "FK_Conversations_Users_UserUUID",
                table: "Conversations",
                column: "UserUUID",
                principalTable: "Users",
                principalColumn: "UUID",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ChatBotMessages_Users_UserUUID",
                table: "ChatBotMessages");

            migrationBuilder.DropForeignKey(
                name: "FK_Conversations_Users_UserUUID",
                table: "Conversations");

            migrationBuilder.DropIndex(
                name: "IX_Conversations_UserUUID",
                table: "Conversations");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "Conversations");

            migrationBuilder.DropColumn(
                name: "Title",
                table: "Conversations");

            migrationBuilder.DropColumn(
                name: "UserUUID",
                table: "Conversations");

            migrationBuilder.RenameColumn(
                name: "IsFromBot",
                table: "ChatBotMessages",
                newName: "isFromBot");

            migrationBuilder.AddForeignKey(
                name: "FK_ChatBotMessages_Users_UserUUID",
                table: "ChatBotMessages",
                column: "UserUUID",
                principalTable: "Users",
                principalColumn: "UUID",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
