using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Billister.Migrations
{
    /// <inheritdoc />
    public partial class AddNotificationsEnabledToSavedSearch : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "NotificationsEnabled",
                table: "SavedSearches",
                type: "INTEGER",
                nullable: false,
                defaultValue: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "NotificationsEnabled",
                table: "SavedSearches");
        }
    }
}
