using Billister.Models;

namespace Billister.Services;

public interface IReviewService
{
    /// <summary>
    /// Create a review and update seller rating
    /// </summary>
    Task<Review> CreateReviewAsync(Guid listingId, Guid sellerId, Guid buyerId, int rating, string? title, string? comment);

    /// <summary>
    /// Get all reviews for a seller with pagination
    /// </summary>
    Task<(List<Review> reviews, int totalCount)> GetSellerReviewsAsync(Guid sellerId, int page = 1, int pageSize = 10);

    /// <summary>
    /// Get reviews for a specific listing
    /// </summary>
    Task<List<Review>> GetListingReviewsAsync(Guid listingId);

    /// <summary>
    /// Get or create seller rating
    /// </summary>
    Task<SellerRating> GetSellerRatingAsync(Guid sellerId);

    /// <summary>
    /// Check if buyer already reviewed a listing from this seller
    /// </summary>
    Task<bool> HasReviewedAsync(Guid listingId, Guid buyerId);
}
