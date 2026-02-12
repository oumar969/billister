namespace Billister.Models;

public sealed class Favorite
{
    public Guid UserId { get; set; }
    public Guid ListingId { get; set; }
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}
