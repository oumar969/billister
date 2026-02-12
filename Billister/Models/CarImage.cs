namespace Billister.Models;

public sealed class CarImage
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid ListingId { get; set; }
    public CarListing? Listing { get; set; }

    public string Url { get; set; } = string.Empty;
    public int SortOrder { get; set; }

    public int? Width { get; set; }
    public int? Height { get; set; }

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}
