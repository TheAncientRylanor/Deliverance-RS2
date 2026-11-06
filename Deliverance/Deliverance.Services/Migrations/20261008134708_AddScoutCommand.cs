using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Deliverance.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddScoutCommand : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ScoutCommands",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ScoutId = table.Column<int>(type: "int", nullable: false),
                    ExecutionCommandId = table.Column<int>(type: "int", nullable: false),
                    CommandText = table.Column<string>(type: "nvarchar(4000)", maxLength: 4000, nullable: false),
                    Status = table.Column<int>(type: "int", nullable: false),
                    Output = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ExitCode = table.Column<int>(type: "int", nullable: true),
                    CreatedByUserUUID = table.Column<Guid>(type: "UNIQUEIDENTIFIER", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    CompletedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ScoutCommands", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ScoutCommands_ExecutionCommands_ExecutionCommandId",
                        column: x => x.ExecutionCommandId,
                        principalTable: "ExecutionCommands",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ScoutCommands_Scouts_ScoutId",
                        column: x => x.ScoutId,
                        principalTable: "Scouts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ScoutCommands_Users_CreatedByUserUUID",
                        column: x => x.CreatedByUserUUID,
                        principalTable: "Users",
                        principalColumn: "UUID",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ScoutCommands_CreatedByUserUUID",
                table: "ScoutCommands",
                column: "CreatedByUserUUID");

            migrationBuilder.CreateIndex(
                name: "IX_ScoutCommands_ExecutionCommandId",
                table: "ScoutCommands",
                column: "ExecutionCommandId");

            migrationBuilder.CreateIndex(
                name: "IX_ScoutCommands_ScoutId_CreatedAt",
                table: "ScoutCommands",
                columns: new[] { "ScoutId", "CreatedAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ScoutCommands");
        }
    }
}
