using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Deliverance.Services.Migrations
{
    /// <inheritdoc />
    public partial class ReplaceTskWithScoutEnrollment : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "TSK");

            migrationBuilder.CreateTable(
                name: "ScoutEnrollments",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    TokenHash = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: false),
                    CreatedByUserUUID = table.Column<Guid>(type: "UNIQUEIDENTIFIER", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Status = table.Column<int>(type: "int", nullable: false),
                    IpAddress = table.Column<string>(type: "nvarchar(45)", maxLength: 45, nullable: true),
                    MacAddress = table.Column<string>(type: "nvarchar(17)", maxLength: 17, nullable: true),
                    SubnetMask = table.Column<string>(type: "nvarchar(45)", maxLength: 45, nullable: true),
                    VlanID = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: true),
                    OS = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    Manufacturer = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    Hostname = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    ClaimedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    ScoutId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ScoutEnrollments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ScoutEnrollments_Scouts_ScoutId",
                        column: x => x.ScoutId,
                        principalTable: "Scouts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_ScoutEnrollments_Users_CreatedByUserUUID",
                        column: x => x.CreatedByUserUUID,
                        principalTable: "Users",
                        principalColumn: "UUID",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ScoutEnrollments_CreatedByUserUUID",
                table: "ScoutEnrollments",
                column: "CreatedByUserUUID");

            migrationBuilder.CreateIndex(
                name: "IX_ScoutEnrollments_ScoutId",
                table: "ScoutEnrollments",
                column: "ScoutId");

            migrationBuilder.CreateIndex(
                name: "IX_ScoutEnrollments_TokenHash",
                table: "ScoutEnrollments",
                column: "TokenHash",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ScoutEnrollments");

            migrationBuilder.CreateTable(
                name: "TSK",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    RequestedByUserUUID = table.Column<Guid>(type: "UNIQUEIDENTIFIER", nullable: false),
                    ScoutId = table.Column<int>(type: "int", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Key = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Status = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TSK", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TSK_Scouts_ScoutId",
                        column: x => x.ScoutId,
                        principalTable: "Scouts",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_TSK_Users_RequestedByUserUUID",
                        column: x => x.RequestedByUserUUID,
                        principalTable: "Users",
                        principalColumn: "UUID",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_TSK_RequestedByUserUUID",
                table: "TSK",
                column: "RequestedByUserUUID");

            migrationBuilder.CreateIndex(
                name: "IX_TSK_ScoutId",
                table: "TSK",
                column: "ScoutId");
        }
    }
}
