using Billister.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace Billister.Data;

// Enables: dotnet ef migrations add ... (design-time DbContext creation)
public sealed class BillisterDbContextFactory : IDesignTimeDbContextFactory<BillisterDbContext>
{
    public BillisterDbContext CreateDbContext(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<BillisterDbContext>();

        // Keep design-time connection simple; can be overridden with --connection if needed.
        optionsBuilder.UseSqlite("Data Source=billister.db");

        return new BillisterDbContext(optionsBuilder.Options);
    }
}
