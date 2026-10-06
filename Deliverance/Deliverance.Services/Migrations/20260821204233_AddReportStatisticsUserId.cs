using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Deliverance.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddReportStatisticsUserId : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Offices_Users_UserUUID",
                table: "Offices");

            migrationBuilder.AddColumn<Guid>(
                name: "UserId",
                table: "ReportStatistics",
                type: "UNIQUEIDENTIFIER",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AlterColumn<Guid>(
                name: "UserUUID",
                table: "Reports",
                type: "UNIQUEIDENTIFIER",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "UNIQUEIDENTIFIER",
                oldNullable: true);

            migrationBuilder.AlterColumn<Guid>(
                name: "UserUUID",
                table: "Offices",
                type: "UNIQUEIDENTIFIER",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "UNIQUEIDENTIFIER",
                oldNullable: true);

            migrationBuilder.AlterColumn<Guid>(
                name: "UserUUID",
                table: "Contacts",
                type: "UNIQUEIDENTIFIER",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "UNIQUEIDENTIFIER",
                oldNullable: true);

            migrationBuilder.AlterColumn<Guid>(
                name: "UserUUID",
                table: "ChatBotMessages",
                type: "UNIQUEIDENTIFIER",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "UNIQUEIDENTIFIER",
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_ReportStatistics_UserId",
                table: "ReportStatistics",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_Offices_Users_UserUUID",
                table: "Offices",
                column: "UserUUID",
                principalTable: "Users",
                principalColumn: "UUID",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_ReportStatistics_Users_UserId",
                table: "ReportStatistics",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "UUID",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Offices_Users_UserUUID",
                table: "Offices");

            migrationBuilder.DropForeignKey(
                name: "FK_ReportStatistics_Users_UserId",
                table: "ReportStatistics");

            migrationBuilder.DropIndex(
                name: "IX_ReportStatistics_UserId",
                table: "ReportStatistics");

            migrationBuilder.DropColumn(
                name: "UserId",
                table: "ReportStatistics");

            migrationBuilder.AlterColumn<Guid>(
                name: "UserUUID",
                table: "Reports",
                type: "UNIQUEIDENTIFIER",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "UNIQUEIDENTIFIER");

            migrationBuilder.AlterColumn<Guid>(
                name: "UserUUID",
                table: "Offices",
                type: "UNIQUEIDENTIFIER",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "UNIQUEIDENTIFIER");

            migrationBuilder.AlterColumn<Guid>(
                name: "UserUUID",
                table: "Contacts",
                type: "UNIQUEIDENTIFIER",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "UNIQUEIDENTIFIER");

            migrationBuilder.AlterColumn<Guid>(
                name: "UserUUID",
                table: "ChatBotMessages",
                type: "UNIQUEIDENTIFIER",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "UNIQUEIDENTIFIER");

            migrationBuilder.AddForeignKey(
                name: "FK_Offices_Users_UserUUID",
                table: "Offices",
                column: "UserUUID",
                principalTable: "Users",
                principalColumn: "UUID");
        }
    }
}
