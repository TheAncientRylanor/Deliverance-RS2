using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace Deliverance.Services.Migrations
{
    /// <inheritdoc />
    public partial class UserFix1 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<DateTime>(
                name: "UpdatedAt",
                table: "Users",
                type: "datetime2",
                nullable: true,
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<string>(
                name: "ImagePath",
                table: "Users",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.InsertData(
                table: "Users",
                columns: new[] { "UUID", "CreatedAt", "Email", "FirstName", "ImagePath", "LastName", "PasswordHash", "PasswordSalt", "RoleId", "UpdatedAt", "Username" },
                values: new object[,]
                {
                    { new Guid("01a0052b-e3cb-705b-8a0c-ddabfee50ed7"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "abdi@gmail.com", "Abdulah", null, "Gavran", "RAIXbMb2/r260dX5FUyrdjWQD/Y=", "MaguMBrUKFKhR2pJTHh6hQ==", 1, null, "Abdi" },
                    { new Guid("01a0052b-e4b5-766a-b7c6-d601dbfaef87"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "admin@gmail.com", "Admin", null, "Admin", "FtGuYztT2jlsiedsnAooX7e85Uk=", "3+dabjBBHJqaMD7TU5/z9w==", 2, null, "Admin" }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "UUID",
                keyValue: new Guid("01a0052b-e3cb-705b-8a0c-ddabfee50ed7"));

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "UUID",
                keyValue: new Guid("01a0052b-e4b5-766a-b7c6-d601dbfaef87"));

            migrationBuilder.AlterColumn<DateTime>(
                name: "UpdatedAt",
                table: "Users",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified),
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "ImagePath",
                table: "Users",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);
        }
    }
}
