using Microsoft.AspNetCore.Identity;

namespace Billister.Models;

public sealed class ApplicationUser : IdentityUser<Guid>
{
    public string? DisplayName { get; set; }
}

public sealed class ApplicationRole : IdentityRole<Guid>
{
}
