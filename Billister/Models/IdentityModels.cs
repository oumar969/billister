using Microsoft.AspNetCore.Identity;

namespace Billister.Models;

public sealed class ApplicationUser : IdentityUser<Guid>
{
}

public sealed class ApplicationRole : IdentityRole<Guid>
{
}
