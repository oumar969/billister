using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Billister.Migrations
{
    /// <inheritdoc />
    public partial class AddIsDraftToCarListing : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsDraft",
                table: "CarListings",
                type: "INTEGER",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsDraft",
                table: "CarListings");
        }
    }
}
