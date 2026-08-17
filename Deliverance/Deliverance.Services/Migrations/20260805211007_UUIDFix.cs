using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Deliverance.Services.Migrations
{
    /// <inheritdoc />
    public partial class UUIDFix : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_RefreshTokens_Users_UserUUID",
                table: "RefreshTokens");

            migrationBuilder.DropIndex(
                name: "IX_RefreshTokens_UserUUID",
                table: "RefreshTokens");

            migrationBuilder.DropForeignKey(
                name: "FK_ChatBotMessages_Users_UserId",
                table: "ChatBotMessages");

            migrationBuilder.DropForeignKey(
                name: "FK_Contacts_Users_UserId",
                table: "Contacts");

            migrationBuilder.DropForeignKey(
                name: "FK_Reports_Users_UserId",
                table: "Reports");

            migrationBuilder.DropForeignKey(
                name: "FK_TSK_Users_RequestedByUserId",
                table: "TSK");

            migrationBuilder.DropUniqueConstraint(
                name: "AK_Users_UUID",
                table: "Users");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Users",
                table: "Users");

            migrationBuilder.DropIndex(
                name: "IX_TSK_RequestedByUserId",
                table: "TSK");

            migrationBuilder.DropIndex(
                name: "IX_Reports_UserId",
                table: "Reports");

            migrationBuilder.DropIndex(
                name: "IX_Contacts_UserId",
                table: "Contacts");

            migrationBuilder.DropIndex(
                name: "IX_ChatBotMessages_UserId",
                table: "ChatBotMessages");

            migrationBuilder.DropColumn(
                name: "Id",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "RequestedByUserId",
                table: "TSK");

            migrationBuilder.DropColumn(
                name: "UserId",
                table: "Reports");

            migrationBuilder.DropColumn(
                name: "UserId",
                table: "Contacts");

            migrationBuilder.DropColumn(
                name: "UserId",
                table: "ChatBotMessages");

            migrationBuilder.AddColumn<Guid>(
                name: "RequestedByUserUUID",
                table: "TSK",
                type: "UNIQUEIDENTIFIER",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddColumn<Guid>(
                name: "UserUUID",
                table: "Reports",
                type: "UNIQUEIDENTIFIER",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "UserUUID",
                table: "Contacts",
                type: "UNIQUEIDENTIFIER",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "UserUUID",
                table: "ChatBotMessages",
                type: "UNIQUEIDENTIFIER",
                nullable: true);

            migrationBuilder.AddPrimaryKey(
                name: "PK_Users",
                table: "Users",
                column: "UUID");

            migrationBuilder.CreateIndex(
                name: "IX_RefreshTokens_UserUUID",
                table: "RefreshTokens",
                column: "UserUUID");

            migrationBuilder.AddForeignKey(
                name: "FK_RefreshTokens_Users_UserUUID",
                table: "RefreshTokens",
                column: "UserUUID",
                principalTable: "Users",
                principalColumn: "UUID",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.CreateIndex(
                name: "IX_TSK_RequestedByUserUUID",
                table: "TSK",
                column: "RequestedByUserUUID");

            migrationBuilder.CreateIndex(
                name: "IX_Reports_UserUUID",
                table: "Reports",
                column: "UserUUID");

            migrationBuilder.CreateIndex(
                name: "IX_Contacts_UserUUID",
                table: "Contacts",
                column: "UserUUID");

            migrationBuilder.CreateIndex(
                name: "IX_ChatBotMessages_UserUUID",
                table: "ChatBotMessages",
                column: "UserUUID");

            migrationBuilder.AddForeignKey(
                name: "FK_ChatBotMessages_Users_UserUUID",
                table: "ChatBotMessages",
                column: "UserUUID",
                principalTable: "Users",
                principalColumn: "UUID",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Contacts_Users_UserUUID",
                table: "Contacts",
                column: "UserUUID",
                principalTable: "Users",
                principalColumn: "UUID",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Reports_Users_UserUUID",
                table: "Reports",
                column: "UserUUID",
                principalTable: "Users",
                principalColumn: "UUID",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_TSK_Users_RequestedByUserUUID",
                table: "TSK",
                column: "RequestedByUserUUID",
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

            migrationBuilder.DropIndex(
                name: "IX_RefreshTokens_UserUUID",
                table: "RefreshTokens");

            migrationBuilder.DropForeignKey(
                name: "FK_ChatBotMessages_Users_UserUUID",
                table: "ChatBotMessages");

            migrationBuilder.DropForeignKey(
                name: "FK_Contacts_Users_UserUUID",
                table: "Contacts");

            migrationBuilder.DropForeignKey(
                name: "FK_Reports_Users_UserUUID",
                table: "Reports");

            migrationBuilder.DropForeignKey(
                name: "FK_TSK_Users_RequestedByUserUUID",
                table: "TSK");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Users",
                table: "Users");

            migrationBuilder.DropIndex(
                name: "IX_TSK_RequestedByUserUUID",
                table: "TSK");

            migrationBuilder.DropIndex(
                name: "IX_Reports_UserUUID",
                table: "Reports");

            migrationBuilder.DropIndex(
                name: "IX_Contacts_UserUUID",
                table: "Contacts");

            migrationBuilder.DropIndex(
                name: "IX_ChatBotMessages_UserUUID",
                table: "ChatBotMessages");

            migrationBuilder.DropColumn(
                name: "RequestedByUserUUID",
                table: "TSK");

            migrationBuilder.DropColumn(
                name: "UserUUID",
                table: "Reports");

            migrationBuilder.DropColumn(
                name: "UserUUID",
                table: "Contacts");

            migrationBuilder.DropColumn(
                name: "UserUUID",
                table: "ChatBotMessages");

            migrationBuilder.AddColumn<int>(
                name: "Id",
                table: "Users",
                type: "int",
                nullable: false,
                defaultValue: 0)
                .Annotation("SqlServer:Identity", "1, 1");

            migrationBuilder.AddColumn<int>(
                name: "RequestedByUserId",
                table: "TSK",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "UserId",
                table: "Reports",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "UserId",
                table: "Contacts",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "UserId",
                table: "ChatBotMessages",
                type: "int",
                nullable: true);

            migrationBuilder.AddUniqueConstraint(
                name: "AK_Users_UUID",
                table: "Users",
                column: "UUID");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Users",
                table: "Users",
                column: "Id");

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

            migrationBuilder.CreateIndex(
                name: "IX_TSK_RequestedByUserId",
                table: "TSK",
                column: "RequestedByUserId");

            migrationBuilder.CreateIndex(
                name: "IX_Reports_UserId",
                table: "Reports",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Contacts_UserId",
                table: "Contacts",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_ChatBotMessages_UserId",
                table: "ChatBotMessages",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_ChatBotMessages_Users_UserId",
                table: "ChatBotMessages",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Contacts_Users_UserId",
                table: "Contacts",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Reports_Users_UserId",
                table: "Reports",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_TSK_Users_RequestedByUserId",
                table: "TSK",
                column: "RequestedByUserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
