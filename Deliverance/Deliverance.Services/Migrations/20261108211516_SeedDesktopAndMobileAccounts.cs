using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Deliverance.Services.Migrations
{
    /// <inheritdoc />
    public partial class SeedDesktopAndMobileAccounts : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "UUID",
                keyValue: new Guid("01a0052b-e3cb-705b-8a0c-ddabfee50ed7"),
                columns: new[] { "Email", "FirstName", "LastName", "PasswordHash", "PasswordSalt", "Username" },
                values: new object[] { "mobile@deliverance.com", "Mobile", "User", "pbkdf2-sha256$600000$jBl4IUJ9RgcaWQU6lyeljCkr6K2D/oXtwP38q0PLDeg=", "Ies/D2F0M/FmsJ1dOaHmzg==", "mobile" });

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "UUID",
                keyValue: new Guid("01a0052b-e4b5-766a-b7c6-d601dbfaef87"),
                columns: new[] { "Email", "FirstName", "PasswordHash", "PasswordSalt", "Username" },
                values: new object[] { "desktop@deliverance.com", "Desktop", "pbkdf2-sha256$600000$UPhzXj+DI+68beIrDPvxEMFkPWIn7q+bpXoGogYSPj0=", "fU/wbIMst4WNAlKkvPNLuA==", "desktop" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "UUID",
                keyValue: new Guid("01a0052b-e3cb-705b-8a0c-ddabfee50ed7"),
                columns: new[] { "Email", "FirstName", "LastName", "PasswordHash", "PasswordSalt", "Username" },
                values: new object[] { "abdi@gmail.com", "Abdulah", "Gavran", "RAIXbMb2/r260dX5FUyrdjWQD/Y=", "MaguMBrUKFKhR2pJTHh6hQ==", "Abdi" });

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "UUID",
                keyValue: new Guid("01a0052b-e4b5-766a-b7c6-d601dbfaef87"),
                columns: new[] { "Email", "FirstName", "PasswordHash", "PasswordSalt", "Username" },
                values: new object[] { "admin@gmail.com", "Admin", "FtGuYztT2jlsiedsnAooX7e85Uk=", "3+dabjBBHJqaMD7TU5/z9w==", "Admin" });
        }
    }
}
