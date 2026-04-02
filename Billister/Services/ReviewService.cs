using Billister.Data;
using Billister.Models;
using Microsoft.EntityFrameworkCore;

namespace Billister.Services;

public sealed class ReviewService : IReviewService
{
    private readonly BillisterDbContext _db;

    public ReviewService(BillisterDbContext db)
    {
        _db = db;
    }

    public async Task<Review> CreateReviewAsync(
        Guid listingId,
        Guid sellerId,
        Guid buyerId,
        int rating,
        string? title,
        string? comment)
    {
        if (rating < 1 || rating > 5)
            throw new ArgumentException("Rating must be between 1 and 5");

        var review = new Review
        {
            Id = Guid.NewGuid(),
            ListingId = listingId,
            SellerUserId = sellerId,
            BuyerUserId = buyerId,
            Rating = rating,
            Title = title?.Trim(),
            Comment = comment?.Trim(),
            CreatedAtUtc = DateTime.UtcNow,
            UpdatedAtUtc = DateTime.UtcNow
        };

        _db.Reviews.Add(review);
        await _db.SaveChangesAsync();

        // Update seller rating
        await UpdateSellerRatingAsync(sellerId);

        return review;
    }

    public async Task<(List<Review> reviews, int totalCount)> GetSellerReviewsAsync(
        Guid sellerId,
        int page = 1,
        int pageSize = 10)
    {
        var query = _db.Reviews
            .Where(r => r.SellerUserId == sellerId)
            .OrderByDescending(r => r.CreatedAtUtc)
            .Include(r => r.Buyer);

        var totalCount = await query.CountAsync();
        var reviews = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return (reviews, totalCount);
    }

    public async Task<List<Review>> GetListingReviewsAsync(Guid listingId)
    {
        return await _db.Reviews
            .Where(r => r.ListingId == listingId)
            .OrderByDescending(r => r.CreatedAtUtc)
            .Include(r => r.Buyer)
            .ToListAsync();
    }

    public async Task<SellerRating> GetSellerRatingAsync(Guid sellerId)
    {
        var rating = await _db.SellerRatings.FirstOrDefaultAsync(r => r.SellerId == sellerId);

        if (rating == null)
        {
            rating = new SellerRating
            {
                SellerId = sellerId,
                TotalReviews = 0,
                AverageRating = 0,
                LastUpdatedUtc = DateTime.UtcNow
            };
            _db.SellerRatings.Add(rating);
            await _db.SaveChangesAsync();
        }

        return rating;
    }

    public async Task<bool> HasReviewedAsync(Guid listingId, Guid buyerId)
    {
        return await _db.Reviews
            .AnyAsync(r => r.ListingId == listingId && r.BuyerUserId == buyerId);
    }

    private async Task UpdateSellerRatingAsync(Guid sellerId)
    {
        var reviews = await _db.Reviews
            .Where(r => r.SellerUserId == sellerId)
            .ToListAsync();

        if (!reviews.Any())
            return;

        var totalCount = reviews.Count;
        var averageRating = reviews.Average(r => r.Rating);

        var rating = await _db.SellerRatings.FirstOrDefaultAsync(r => r.SellerId == sellerId);

        if (rating == null)
        {
            rating = new SellerRating { SellerId = sellerId };
            _db.SellerRatings.Add(rating);
        }

        rating.TotalReviews = totalCount;
        rating.AverageRating = (decimal)averageRating;
        rating.FiveStarCount = reviews.Count(r => r.Rating == 5);
        rating.FourStarCount = reviews.Count(r => r.Rating == 4);
        rating.ThreeStarCount = reviews.Count(r => r.Rating == 3);
        rating.TwoStarCount = reviews.Count(r => r.Rating == 2);
        rating.OneStarCount = reviews.Count(r => r.Rating == 1);
        rating.LastUpdatedUtc = DateTime.UtcNow;

        await _db.SaveChangesAsync();
    }
}
