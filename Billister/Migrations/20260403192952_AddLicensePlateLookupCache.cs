using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Billister.Migrations
{
    /// <inheritdoc />
    public partial class AddLicensePlateLookupCache : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "FirstRegistrationYear",
                table: "CarListings",
                type: "INTEGER",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsLeasing",
                table: "CarListings",
                type: "INTEGER",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "SaleType",
                table: "CarListings",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SellerType",
                table: "CarListings",
                type: "TEXT",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "LicensePlateLookupCaches",
                columns: table => new
                {
                    Id = table.Column<string>(type: "TEXT", nullable: false),
                    LicensePlate = table.Column<string>(type: "TEXT", nullable: false),
                    Make = table.Column<string>(type: "TEXT", nullable: false),
                    Model = table.Column<string>(type: "TEXT", nullable: false),
                    Year = table.Column<int>(type: "INTEGER", nullable: true),
                    FuelType = table.Column<string>(type: "TEXT", nullable: true),
                    Transmission = table.Column<string>(type: "TEXT", nullable: true),
                    Kilometers = table.Column<int>(type: "INTEGER", nullable: true),
                    EngineSize = table.Column<string>(type: "TEXT", nullable: true),
                    Color = table.Column<string>(type: "TEXT", nullable: true),
                    Co2Emissions = table.Column<int>(type: "INTEGER", nullable: true),
                    EuroStandard = table.Column<string>(type: "TEXT", nullable: true),
                    RawJsonData = table.Column<string>(type: "TEXT", nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "TEXT", nullable: false),
                    LastAccessedAtUtc = table.Column<DateTime>(type: "TEXT", nullable: false),
                    AccessCount = table.Column<int>(type: "INTEGER", nullable: false),
                    ErrorMessage = table.Column<string>(type: "TEXT", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LicensePlateLookupCaches", x => x.Id);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "LicensePlateLookupCaches");

            migrationBuilder.DropColumn(
                name: "FirstRegistrationYear",
                table: "CarListings");

            migrationBuilder.DropColumn(
                name: "IsLeasing",
                table: "CarListings");

            migrationBuilder.DropColumn(
                name: "SaleType",
                table: "CarListings");

            migrationBuilder.DropColumn(
                name: "SellerType",
                table: "CarListings");
        }
    }
}
