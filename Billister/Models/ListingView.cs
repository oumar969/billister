namespace Billister.Models;

public sealed class ListingView
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid ListingId { get; set; }

    public Guid? ViewerUserId { get; set; }
    public string? ViewerIp { get; set; }

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}
