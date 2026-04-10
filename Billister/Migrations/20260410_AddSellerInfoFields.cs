using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Billister.Migrations
{
    /// <inheritdoc />
    public partial class AddSellerInfoFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "CvrNumber",
                table: "CarListings",
                type: "TEXT",
                maxLength: 30,
                nullable: true,
                comment: "CVR nummer for registrerede virksomheder");

            migrationBuilder.AddColumn<string>(
                name: "StreetAddress",
                table: "CarListings",
                type: "TEXT",
                maxLength: 120,
                nullable: true,
                comment: "Vejnavn (e.g. Strandvejen)");

            migrationBuilder.AddColumn<string>(
                name: "StreetNumber",
                table: "CarListings",
                type: "TEXT",
                maxLength: 20,
                nullable: true,
                comment: "Husnummer (e.g. 34)");

            migrationBuilder.AddColumn<string>(
                name: "Floor",
                table: "CarListings",
                type: "TEXT",
                maxLength: 30,
                nullable: true,
                comment: "Etage/Enhedsnummer (e.g. st. th.)");

            migrationBuilder.AddColumn<string>(
                name: "Website",
                table: "CarListings",
                type: "TEXT",
                maxLength: 300,
                nullable: true,
                comment: "Sælger hjemmeside");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CvrNumber",
                table: "CarListings");

            migrationBuilder.DropColumn(
                name: "StreetAddress",
                table: "CarListings");

            migrationBuilder.DropColumn(
                name: "StreetNumber",
                table: "CarListings");

            migrationBuilder.DropColumn(
                name: "Floor",
                table: "CarListings");

            migrationBuilder.DropColumn(
                name: "Website",
                table: "CarListings");
        }
    }
}
