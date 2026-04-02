using Billister.Contracts;
using Billister.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Billister.Controllers;

[ApiController]
[Route("api/reviews")]
public sealed class ReviewsController : ControllerBase
{
    private readonly IReviewService _reviewService;

    public ReviewsController(IReviewService reviewService)
    {
        _reviewService = reviewService;
    }

    [Authorize]
    [HttpPost]
    public async Task<IActionResult> CreateReview(
        [FromQuery] Guid listingId,
        [FromQuery] Guid sellerId,
        [FromBody] ApiDtos.Reviews.CreateReviewRequest req)
    {
        if (listingId == Guid.Empty || sellerId == Guid.Empty)
            return BadRequest(new { error = "Listing ID og Seller ID er påkrævet" });

        // Get buyer ID from token
        var buyerIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(buyerIdClaim) || !Guid.TryParse(buyerIdClaim, out var buyerId))
            return Unauthorized(new { error = "Bruger ikke fundet" });

        if (buyerId == sellerId)
            return BadRequest(new { error = "Du kan ikke bedømme dine egne annoncer" });

        // Check if already reviewed
        if (await _reviewService.HasReviewedAsync(listingId, buyerId))
            return BadRequest(new { error = "Du har allerede bedømt denne annonce" });

        try
        {
            var review = await _reviewService.CreateReviewAsync(
                listingId,
                sellerId,
                buyerId,
                req.Rating,
                req.Title,
                req.Comment);

            return Ok(new { message = "Anmeldelse oprettet", reviewId = review.Id });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("seller/{sellerId}")]
    public async Task<IActionResult> GetSellerReviews(
        [FromRoute] Guid sellerId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10)
    {
        if (sellerId == Guid.Empty)
            return BadRequest(new { error = "Seller ID er påkrævet" });

        if (page < 1) page = 1;
        if (pageSize < 1 || pageSize > 50) pageSize = 10;

        var (reviews, totalCount) = await _reviewService.GetSellerReviewsAsync(sellerId, page, pageSize);

        var reviewDtos = reviews.Select(r => new ApiDtos.Reviews.ReviewDto(
            r.Id,
            r.ListingId,
            r.BuyerUserId,
            r.Buyer?.UserName ?? "Anonym",
            r.Rating,
            r.Title,
            r.Comment,
            r.CreatedAtUtc)).ToList();

        var response = new ApiDtos.Reviews.ReviewsPageDto(
            reviewDtos,
            page,
            pageSize,
            totalCount);

        return Ok(response);
    }

    [HttpGet("seller-rating/{sellerId}")]
    public async Task<IActionResult> GetSellerRating([FromRoute] Guid sellerId)
    {
        if (sellerId == Guid.Empty)
            return BadRequest(new { error = "Seller ID er påkrævet" });

        var rating = await _reviewService.GetSellerRatingAsync(sellerId);

        var ratingDto = new ApiDtos.Reviews.SellerRatingDto(
            rating.SellerId,
            rating.TotalReviews,
            rating.AverageRating,
            rating.FiveStarCount,
            rating.FourStarCount,
            rating.ThreeStarCount,
            rating.TwoStarCount,
            rating.OneStarCount);

        return Ok(ratingDto);
    }

    [HttpGet("listing/{listingId}")]
    public async Task<IActionResult> GetListingReviews([FromRoute] Guid listingId)
    {
        if (listingId == Guid.Empty)
            return BadRequest(new { error = "Listing ID er påkrævet" });

        var reviews = await _reviewService.GetListingReviewsAsync(listingId);

        var reviewDtos = reviews.Select(r => new ApiDtos.Reviews.ReviewDto(
            r.Id,
            r.ListingId,
            r.BuyerUserId,
            r.Buyer?.UserName ?? "Anonym",
            r.Rating,
            r.Title,
            r.Comment,
            r.CreatedAtUtc)).ToList();

        return Ok(reviewDtos);
    }
}
