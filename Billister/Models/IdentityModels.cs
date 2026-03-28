using Microsoft.AspNetCore.Identity;

namespace Billister.Models;

public sealed class ApplicationUser : IdentityUser<Guid>
{
    public string? VerificationCode { get; set; }
    public DateTime? VerificationCodeExpiry { get; set; }
}

public sealed class ApplicationRole : IdentityRole<Guid>
{
}
