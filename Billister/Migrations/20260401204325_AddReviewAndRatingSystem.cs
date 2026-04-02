using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Billister.Migrations
{
    /// <inheritdoc />
    public partial class AddReviewAndRatingSystem : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Reviews",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    ListingId = table.Column<Guid>(type: "TEXT", nullable: false),
                    SellerUserId = table.Column<Guid>(type: "TEXT", nullable: false),
                    BuyerUserId = table.Column<Guid>(type: "TEXT", nullable: false),
                    Rating = table.Column<int>(type: "INTEGER", nullable: false),
                    Title = table.Column<string>(type: "TEXT", maxLength: 200, nullable: true),
                    Comment = table.Column<string>(type: "TEXT", maxLength: 2000, nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Reviews", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Reviews_AspNetUsers_BuyerUserId",
                        column: x => x.BuyerUserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Reviews_AspNetUsers_SellerUserId",
                        column: x => x.SellerUserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Reviews_CarListings_ListingId",
                        column: x => x.ListingId,
                        principalTable: "CarListings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "SellerRatings",
                columns: table => new
                {
                    SellerId = table.Column<Guid>(type: "TEXT", nullable: false),
                    TotalReviews = table.Column<int>(type: "INTEGER", nullable: false),
                    AverageRating = table.Column<decimal>(type: "TEXT", nullable: false),
                    FiveStarCount = table.Column<int>(type: "INTEGER", nullable: false),
                    FourStarCount = table.Column<int>(type: "INTEGER", nullable: false),
                    ThreeStarCount = table.Column<int>(type: "INTEGER", nullable: false),
                    TwoStarCount = table.Column<int>(type: "INTEGER", nullable: false),
                    OneStarCount = table.Column<int>(type: "INTEGER", nullable: false),
                    LastUpdatedUtc = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SellerRatings", x => x.SellerId);
                    table.ForeignKey(
                        name: "FK_SellerRatings_AspNetUsers_SellerId",
                        column: x => x.SellerId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_BuyerUserId",
                table: "Reviews",
                column: "BuyerUserId");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_ListingId",
                table: "Reviews",
                column: "ListingId");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_SellerUserId",
                table: "Reviews",
                column: "SellerUserId");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_SellerUserId_CreatedAtUtc",
                table: "Reviews",
                columns: new[] { "SellerUserId", "CreatedAtUtc" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Reviews");

            migrationBuilder.DropTable(
                name: "SellerRatings");
        }
    }
}
