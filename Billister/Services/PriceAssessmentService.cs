using Billister.Data;
using Billister.Models;
using Microsoft.EntityFrameworkCore;

namespace Billister.Services;

public interface IPriceAssessmentService
{
    Task<PriceAssessmentResult> AssessPriceAsync(CarListing listing, CancellationToken ct = default);
}

/// <summary>
/// Result of a price assessment for a single listing compared to similar listings on the market.
/// </summary>
public sealed record PriceAssessmentResult(
    decimal ListingPriceDkk,
    int SimilarListingsCount,
    decimal? MedianPriceDkk,
    decimal? AveragePriceDkk,
    decimal? MinPriceDkk,
    decimal? MaxPriceDkk,
    /// <summary>
    /// "under_markedet" | "markedspris" | "over_markedet" | null (insufficient data)
    /// </summary>
    string? Verdict,
    decimal? PriceDifferencePercent,
    IReadOnlyList<SimilarListingSnapshot> SimilarListings);

public sealed record SimilarListingSnapshot(
    Guid Id,
    string Make,
    string Model,
    string? Variant,
    int? Year,
    int? MileageKm,
    decimal PriceDkk,
    string? City,
    string? ThumbnailUrl);

public sealed class PriceAssessmentService : IPriceAssessmentService
{
    private const int MinSimilarForVerdict = 3;
    private const int MaxSimilarReturned = 5;
    private const int MaxSimilarListingsQueried = 50;

    private const int StrictYearRange = 2;
    private const int StrictMileageRange = 30_000;
    private const int LooseYearRange = 5;
    private const int LooseMileageRange = 75_000;

    private readonly BillisterDbContext _db;

    public PriceAssessmentService(BillisterDbContext db)
    {
        _db = db;
    }

    public async Task<PriceAssessmentResult> AssessPriceAsync(CarListing listing, CancellationToken ct = default)
    {
        var similar = await FindSimilarAsync(listing, ct);

        if (similar.Count == 0)
        {
            return new PriceAssessmentResult(
                listing.PriceDkk,
                0,
                null, null, null, null,
                null, null,
                Array.Empty<SimilarListingSnapshot>());
        }

        var prices = similar.Select(x => x.PriceDkk).OrderBy(p => p).ToList();
        var median = Median(prices);
        var average = prices.Average();
        var min = prices.Min();
        var max = prices.Max();

        string? verdict = null;
        decimal? diffPct = null;

        if (similar.Count >= MinSimilarForVerdict && median > 0)
        {
            diffPct = Math.Round((listing.PriceDkk - median) / median * 100, 1);
            verdict = diffPct switch
            {
                < -10 => "under_markedet",
                > 10  => "over_markedet",
                _     => "markedspris"
            };
        }

        var snapshots = similar
            .Take(MaxSimilarReturned)
            .Select(x => new SimilarListingSnapshot(
                x.Id,
                x.Make,
                x.Model,
                x.Variant,
                x.Year,
                x.MileageKm,
                x.PriceDkk,
                x.City,
                x.ThumbnailUrl))
            .ToList();

        return new PriceAssessmentResult(
            listing.PriceDkk,
            similar.Count,
            Math.Round(median, 0),
            Math.Round(average, 0),
            min,
            max,
            verdict,
            diffPct,
            snapshots);
    }

    private async Task<List<SimilarRow>> FindSimilarAsync(CarListing listing, CancellationToken ct)
    {
        // Try strict criteria first (same make+model+fuel, year ±2, mileage ±30k).
        var strict = await QuerySimilarAsync(
            listing,
            yearRange: StrictYearRange,
            mileageRange: StrictMileageRange,
            matchFuelType: true,
            ct);

        if (strict.Count >= MinSimilarForVerdict)
            return strict;

        // Loosen: drop fuel-type requirement and widen year/mileage window.
        var loose = await QuerySimilarAsync(
            listing,
            yearRange: LooseYearRange,
            mileageRange: LooseMileageRange,
            matchFuelType: false,
            ct);

        return loose;
    }

    private async Task<List<SimilarRow>> QuerySimilarAsync(
        CarListing listing,
        int yearRange,
        int mileageRange,
        bool matchFuelType,
        CancellationToken ct)
    {
        IQueryable<CarListing> q = _db.CarListings
            .AsNoTracking()
            .Include(x => x.Images)
            .Where(x => x.Id != listing.Id)
            .Where(x => x.Make == listing.Make && x.Model == listing.Model);

        if (matchFuelType)
            q = q.Where(x => x.FuelType == listing.FuelType);

        if (listing.Year.HasValue)
        {
            var yMin = listing.Year.Value - yearRange;
            var yMax = listing.Year.Value + yearRange;
            q = q.Where(x => x.Year.HasValue && x.Year >= yMin && x.Year <= yMax);
        }

        if (listing.MileageKm.HasValue)
        {
            var mMin = Math.Max(0, listing.MileageKm.Value - mileageRange);
            var mMax = listing.MileageKm.Value + mileageRange;
            q = q.Where(x => x.MileageKm.HasValue && x.MileageKm >= mMin && x.MileageKm <= mMax);
        }

        var rows = await q
            .OrderByDescending(x => x.CreatedAtUtc)
            .Take(MaxSimilarListingsQueried)
            .Select(x => new
            {
                x.Id,
                x.Make,
                x.Model,
                x.Variant,
                x.Year,
                x.MileageKm,
                x.PriceDkk,
                x.City,
                ThumbnailUrl = x.Images
                    .OrderBy(i => i.SortOrder)
                    .Select(i => i.Url)
                    .FirstOrDefault()
            })
            .ToListAsync(ct);

        return rows
            .Select(r => new SimilarRow(r.Id, r.Make, r.Model, r.Variant, r.Year, r.MileageKm, r.PriceDkk, r.City, r.ThumbnailUrl))
            .ToList();
    }

    private static decimal Median(List<decimal> sortedValues)
    {
        var count = sortedValues.Count;
        if (count == 0) return 0;
        if (count % 2 == 1) return sortedValues[count / 2];
        return (sortedValues[count / 2 - 1] + sortedValues[count / 2]) / 2m;
    }

    private sealed record SimilarRow(
        Guid Id,
        string Make,
        string Model,
        string? Variant,
        int? Year,
        int? MileageKm,
        decimal PriceDkk,
        string? City,
        string? ThumbnailUrl);
}
