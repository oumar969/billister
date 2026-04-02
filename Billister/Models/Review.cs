namespace Billister.Models;

public sealed class Review
{
    public Guid Id { get; set; }
    public Guid ListingId { get; set; }
    public Guid SellerUserId { get; set; }
    public Guid BuyerUserId { get; set; }

    public int Rating { get; set; } // 1-5 stars
    public string? Title { get; set; }
    public string? Comment { get; set; }

    public DateTime CreatedAtUtc { get; set; }
    public DateTime UpdatedAtUtc { get; set; }

    // Navigation properties
    public CarListing? Listing { get; set; }
    public ApplicationUser? Seller { get; set; }
    public ApplicationUser? Buyer { get; set; }
}

public sealed class SellerRating
{
    public Guid SellerId { get; set; }

    public int TotalReviews { get; set; }
    public decimal AverageRating { get; set; } // 1.0 - 5.0

    public int FiveStarCount { get; set; }
    public int FourStarCount { get; set; }
    public int ThreeStarCount { get; set; }
    public int TwoStarCount { get; set; }
    public int OneStarCount { get; set; }

    public DateTime LastUpdatedUtc { get; set; }

    // Navigation property
    public ApplicationUser? Seller { get; set; }
}
