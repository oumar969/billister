using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Billister.Migrations
{
    /// <inheritdoc />
    public partial class AddSellerPhoneToCarListing : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "SellerPhone",
                table: "CarListings",
                type: "TEXT",
                maxLength: 30,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "SellerPhone",
                table: "CarListings");
        }
    }
}
