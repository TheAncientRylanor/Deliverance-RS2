using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace Deliverance.Services.Migrations
{
    /// <inheritdoc />
    public partial class SeedOccurances : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "Occurances",
                columns: new[] { "Id", "Question" },
                values: new object[,]
                {
                    { 1, "Have you encountered this problem before?" },
                    { 2, "Have you restarted the device?" },
                    { 3, "Is the device properly connected to power?" },
                    { 4, "Is the device connected to the network?" },
                    { 5, "Has anything changed recently (updates, settings, cables)?" }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "Occurances",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Occurances",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "Occurances",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "Occurances",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "Occurances",
                keyColumn: "Id",
                keyValue: 5);
        }
    }
}
