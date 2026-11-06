using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace Deliverance.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddExecutionCommand : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ExecutionCommands",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ExecutionCommands", x => x.Id);
                });

            migrationBuilder.InsertData(
                table: "ExecutionCommands",
                columns: new[] { "Id", "Name" },
                values: new object[,]
                {
                    { 1, "CMD" },
                    { 2, "PowerShell" }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ExecutionCommands");
        }
    }
}
