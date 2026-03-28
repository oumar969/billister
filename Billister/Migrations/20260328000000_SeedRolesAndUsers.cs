using Billister.Data;
using Microsoft.EntityFrameworkCore.Migrations;
using Microsoft.EntityFrameworkCore.Infrastructure;

#nullable disable

namespace Billister.Migrations
{
    /// <inheritdoc />
    [DbContext(typeof(BillisterDbContext))]
    [Migration("20260328000000_SeedRolesAndUsers")]
    public partial class SeedRolesAndUsers : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Insert Admin role
            migrationBuilder.Sql("""
                INSERT INTO AspNetRoles (Id, Name, NormalizedName, ConcurrencyStamp)
                SELECT '00000000-0000-0000-0000-000000000002', 'Admin', 'ADMIN', '10000000-0000-0000-0000-000000000000'
                WHERE NOT EXISTS (SELECT 1 FROM AspNetRoles WHERE Name = 'Admin');
                """);

            // Insert User role
            migrationBuilder.Sql("""
                INSERT INTO AspNetRoles (Id, Name, NormalizedName, ConcurrencyStamp)
                SELECT '00000000-0000-0000-0000-000000000003', 'User', 'USER', '11000000-0000-0000-0000-000000000000'
                WHERE NOT EXISTS (SELECT 1 FROM AspNetRoles WHERE Name = 'User');
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Remove roles
            migrationBuilder.Sql("""
                DELETE FROM AspNetRoles
                WHERE Id IN ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000003');
                """);
        }
    }
}
