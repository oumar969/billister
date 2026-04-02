using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Billister.Migrations
{
    /// <inheritdoc />
    public partial class AddFilteringFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsLeasing",
                table: "CarListings",
                type: "INTEGER",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "SellerType",
                table: "CarListings",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SaleType",
                table: "CarListings",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "FirstRegistrationYear",
                table: "CarListings",
                type: "INTEGER",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsLeasing",
                table: "CarListings");

            migrationBuilder.DropColumn(
                name: "SellerType",
                table: "CarListings");

            migrationBuilder.DropColumn(
                name: "SaleType",
                table: "CarListings");

            migrationBuilder.DropColumn(
                name: "FirstRegistrationYear",
                table: "CarListings");
        }
    }
}
