using System.Security.Claims;
using System.Text.Json;
using Billister.Contracts;
using Billister.Data;
using Billister.Models;
using Billister.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Billister.Controllers;

[ApiController]
[Route("api/listings")]
public sealed class ListingsController : ControllerBase
{
    private readonly BillisterDbContext _db;
    private readonly IAiDescriptionService _ai;
    private readonly ISavedSearchNotifier _savedSearchNotifier;

    public ListingsController(BillisterDbContext db, IAiDescriptionService ai, ISavedSearchNotifier savedSearchNotifier)
    {
        _db = db;
        _ai = ai;
        _savedSearchNotifier = savedSearchNotifier;
    }

    [HttpGet]
    public async Task<ActionResult<object>> Search([FromQuery] ApiDtos.Listings.ListingQuery query, CancellationToken ct)
    {
        if (query.Page < 1) query = query with { Page = 1 };
        if (query.PageSize is < 1 or > 100) query = query with { PageSize = 20 };

        var criteria = new ListingFilterCriteria
        {
            Q = query.Q,
            Makes = string.IsNullOrWhiteSpace(query.Make) ? null : new List<string> { query.Make },
            Models = string.IsNullOrWhiteSpace(query.Model) ? null : new List<string> { query.Model },
            FuelTypes = string.IsNullOrWhiteSpace(query.FuelType) ? null : new List<string> { query.FuelType },
            Transmissions = string.IsNullOrWhiteSpace(query.Transmission) ? null : new List<string> { query.Transmission },
            PriceMin = query.PriceMin,
            PriceMax = query.PriceMax,
            YearMin = query.YearMin,
            YearMax = query.YearMax,
            MileageMin = query.MileageMin,
            MileageMax = query.MileageMax,
            RangeMin = query.RangeMin,
            RangeMax = query.RangeMax,
            HasTowHook = query.HasTowHook,
            HasFourWheelDrive = query.HasFourWheelDrive,
            RequiredFeatures = string.IsNullOrWhiteSpace(query.Feature) ? null : new List<string> { query.Feature }
        };

        IQueryable<CarListing> q = _db.CarListings.AsNoTracking().Include(x => x.Images);
        q = ApplyCriteria(q, criteria);

        var total = await q.CountAsync(ct);

        var items = await q
            .OrderByDescending(x => x.CreatedAtUtc)
            .Skip((query.Page - 1) * query.PageSize)
            .Take(query.PageSize)
            .Select(x => new
            {
                x.Id,
                x.Make,
                x.Model,
                x.Variant,
                x.PriceDkk,
                x.FuelType,
                x.Transmission,
                x.Year,
                x.MileageKm,
                x.ElectricRangeKm,
                x.Latitude,
                x.Longitude,
                x.City,
                x.ViewCount,
                x.FavoriteCount,
                x.CreatedAtUtc,
                images = x.Images.OrderBy(i => i.SortOrder).Select(i => new { i.Url, i.SortOrder, i.Width, i.Height })
            })
            .ToListAsync(ct);

        return Ok(new { total, page = query.Page, pageSize = query.PageSize, items });
    }

    [HttpPost("search")]
    public async Task<ActionResult<object>> SearchPost([FromBody] ApiDtos.Listings.ListingsSearchRequest request, CancellationToken ct)
    {
        var page = request.Page < 1 ? 1 : request.Page;
        var pageSize = request.PageSize is < 1 or > 100 ? 20 : request.PageSize;

        IQueryable<CarListing> q = _db.CarListings.AsNoTracking().Include(x => x.Images);
        q = ApplyCriteria(q, request.Criteria ?? new ListingFilterCriteria());

        var total = await q.CountAsync(ct);
        var items = await q
            .OrderByDescending(x => x.CreatedAtUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(x => new
            {
                x.Id,
                x.Make,
                x.Model,
                x.Variant,
                x.PriceDkk,
                x.FuelType,
                x.Transmission,
                x.Year,
                x.MileageKm,
                x.ElectricRangeKm,
                x.Latitude,
                x.Longitude,
                x.City,
                x.ViewCount,
                x.FavoriteCount,
                x.CreatedAtUtc,
                images = x.Images.OrderBy(i => i.SortOrder).Select(i => new { i.Url, i.SortOrder, i.Width, i.Height })
            })
            .ToListAsync(ct);

        return Ok(new { total, page, pageSize, items });
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<object>> GetById([FromRoute] Guid id, CancellationToken ct)
    {
        var listing = await _db.CarListings
            .AsNoTracking()
            .Include(x => x.Images)
            .FirstOrDefaultAsync(x => x.Id == id, ct);

        if (listing is null) return NotFound();

        return Ok(new
        {
            listing.Id,
            listing.SellerUserId,
            listing.Make,
            listing.Model,
            listing.Variant,
            listing.Year,
            listing.MileageKm,
            listing.PriceDkk,
            listing.FuelType,
            listing.Transmission,
            listing.ElectricRangeKm,
            listing.BatteryKwh,
            listing.IsPlugInHybrid,
            listing.BodyType,
            listing.Color,
            listing.Doors,
            listing.Seats,
            listing.Horsepower,
            listing.Kilowatts,
            listing.EngineLiters,
            listing.Cylinders,
            listing.HasTowHook,
            listing.HasFourWheelDrive,
            listing.Latitude,
            listing.Longitude,
            listing.PostalCode,
            listing.City,
            listing.Title,
            listing.Description,
            features = JsonSerializer.Deserialize<List<string>>(listing.FeaturesJson) ?? new List<string>(),
            extraAttributes = JsonSerializer.Deserialize<Dictionary<string, object?>>(listing.ExtraAttributesJson) ?? new Dictionary<string, object?>(),
            listing.ViewCount,
            listing.FavoriteCount,
            listing.CreatedAtUtc,
            listing.UpdatedAtUtc,
            images = listing.Images.OrderBy(i => i.SortOrder).Select(i => new { i.Url, i.SortOrder, i.Width, i.Height })
        });
    }

    [Authorize]
    [HttpPost]
    public async Task<ActionResult<object>> Create([FromBody] ApiDtos.Listings.CreateListingRequest req, CancellationToken ct)
    {
        var userId = GetUserId();

        var listing = new CarListing
        {
            SellerUserId = userId,
            Make = req.Make,
            Model = req.Model,
            Variant = req.Variant,
            Year = req.Year,
            MileageKm = req.MileageKm,
            PriceDkk = req.PriceDkk,
            FuelType = req.FuelType,
            Transmission = req.Transmission,
            IsPlugInHybrid = req.IsPlugInHybrid,
            ElectricRangeKm = req.ElectricRangeKm,
            BatteryKwh = req.BatteryKwh,
            BodyType = req.BodyType,
            Color = req.Color,
            Doors = req.Doors,
            Seats = req.Seats,
            Horsepower = req.Horsepower,
            Kilowatts = req.Kilowatts,
            EngineLiters = req.EngineLiters,
            Cylinders = req.Cylinders,
            HasTowHook = req.HasTowHook,
            HasFourWheelDrive = req.HasFourWheelDrive,
            Latitude = req.Latitude,
            Longitude = req.Longitude,
            PostalCode = req.PostalCode,
            City = req.City,
            Title = req.Title,
            Description = req.Description,
            FeaturesJson = JsonSerializer.Serialize(req.Features ?? new List<string>()),
            ExtraAttributesJson = JsonSerializer.Serialize(req.ExtraAttributes ?? new Dictionary<string, object?>())
        };

        if (req.Images is not null)
        {
            foreach (var img in req.Images.OrderBy(i => i.SortOrder))
            {
                listing.Images.Add(new CarImage
                {
                    Url = img.Url,
                    SortOrder = img.SortOrder,
                    Width = img.Width,
                    Height = img.Height
                });
            }
        }

        _db.CarListings.Add(listing);
        await _db.SaveChangesAsync(ct);

        await _savedSearchNotifier.OnNewListingAsync(listing, ct);

        return CreatedAtAction(nameof(GetById), new { id = listing.Id }, new { listing.Id });
    }

    [Authorize]
    [HttpGet("mine")]
    public async Task<ActionResult<object>> Mine([FromQuery] int page = 1, [FromQuery] int pageSize = 20, CancellationToken ct = default)
    {
        if (page < 1) page = 1;
        if (pageSize is < 1 or > 100) pageSize = 20;

        var userId = GetUserId();

        IQueryable<CarListing> q = _db.CarListings
            .AsNoTracking()
            .Include(x => x.Images)
            .Where(x => x.SellerUserId == userId);

        var total = await q.CountAsync(ct);

        var items = await q
            .OrderByDescending(x => x.CreatedAtUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(x => new
            {
                x.Id,
                x.Make,
                x.Model,
                x.Variant,
                x.PriceDkk,
                x.FuelType,
                x.Transmission,
                x.Year,
                x.MileageKm,
                x.ElectricRangeKm,
                x.Latitude,
                x.Longitude,
                x.City,
                x.ViewCount,
                x.FavoriteCount,
                x.CreatedAtUtc,
                images = x.Images.OrderBy(i => i.SortOrder).Select(i => new { i.Url, i.SortOrder, i.Width, i.Height })
            })
            .ToListAsync(ct);

        return Ok(new { total, page, pageSize, items });
    }

    [Authorize]
    [HttpPatch("{id:guid}")]
    public async Task<ActionResult> Update([FromRoute] Guid id, [FromBody] ApiDtos.Listings.UpdateListingRequest req, CancellationToken ct)
    {
        var userId = GetUserId();
        var listing = await _db.CarListings.Include(x => x.Images).FirstOrDefaultAsync(x => x.Id == id, ct);
        if (listing is null) return NotFound();
        if (listing.SellerUserId != userId) return Forbid();

        if (req.PriceDkk is not null) listing.PriceDkk = req.PriceDkk.Value;
        if (req.MileageKm is not null) listing.MileageKm = req.MileageKm;
        if (req.Title is not null) listing.Title = req.Title;
        if (req.Description is not null) listing.Description = req.Description;

        if (req.Features is not null)
        {
            listing.FeaturesJson = JsonSerializer.Serialize(req.Features);
        }

        if (req.ExtraAttributes is not null)
        {
            listing.ExtraAttributesJson = JsonSerializer.Serialize(req.ExtraAttributes);
        }

        if (req.Images is not null)
        {
            listing.Images.Clear();
            foreach (var img in req.Images.OrderBy(i => i.SortOrder))
            {
                listing.Images.Add(new CarImage
                {
                    Url = img.Url,
                    SortOrder = img.SortOrder,
                    Width = img.Width,
                    Height = img.Height
                });
            }
        }

        listing.UpdatedAtUtc = DateTime.UtcNow;
        await _db.SaveChangesAsync(ct);
        return NoContent();
    }

    [Authorize]
    [HttpDelete("{id:guid}")]
    public async Task<ActionResult> Delete([FromRoute] Guid id, CancellationToken ct)
    {
        var userId = GetUserId();
        var listing = await _db.CarListings.FirstOrDefaultAsync(x => x.Id == id, ct);
        if (listing is null) return NotFound();
        if (listing.SellerUserId != userId) return Forbid();

        _db.CarListings.Remove(listing);
        await _db.SaveChangesAsync(ct);
        return NoContent();
    }

    [HttpPost("{id:guid}/view")]
    public async Task<ActionResult> RegisterView([FromRoute] Guid id, CancellationToken ct)
    {
        var listing = await _db.CarListings.FirstOrDefaultAsync(x => x.Id == id, ct);
        if (listing is null) return NotFound();

        listing.ViewCount += 1;

        Guid? viewerId = null;
        if (User.Identity?.IsAuthenticated == true)
        {
            viewerId = GetUserId();
        }

        _db.ListingViews.Add(new ListingView
        {
            ListingId = id,
            ViewerUserId = viewerId,
            ViewerIp = HttpContext.Connection.RemoteIpAddress?.ToString()
        });

        await _db.SaveChangesAsync(ct);
        return NoContent();
    }

    [HttpGet("nearby")]
    public async Task<ActionResult<object>> Nearby([FromQuery] double lat, [FromQuery] double lng, [FromQuery] double radiusKm = 25, CancellationToken ct = default)
    {
        // Simple approximation (bounding box). Can be replaced with proper geo queries later.
        var degreeRadius = radiusKm / 111.0;

        var items = await _db.CarListings
            .AsNoTracking()
            .Where(x => x.Latitude != null && x.Longitude != null)
            .Where(x => x.Latitude >= lat - degreeRadius && x.Latitude <= lat + degreeRadius)
            .Where(x => x.Longitude >= lng - degreeRadius && x.Longitude <= lng + degreeRadius)
            .OrderByDescending(x => x.CreatedAtUtc)
            .Take(200)
            .Select(x => new { x.Id, x.Make, x.Model, x.PriceDkk, x.Latitude, x.Longitude })
            .ToListAsync(ct);

        return Ok(new { items });
    }

    [Authorize]
    [HttpPost("compare")]
    public async Task<ActionResult<object>> Compare([FromBody] Guid[] listingIds, CancellationToken ct)
    {
        if (listingIds.Length is < 2 or > 3) return BadRequest(new { error = "compare requires 2-3 ids" });

        var items = await _db.CarListings
            .AsNoTracking()
            .Where(x => listingIds.Contains(x.Id))
            .Select(x => new
            {
                x.Id,
                x.Make,
                x.Model,
                x.Variant,
                x.PriceDkk,
                x.FuelType,
                x.Transmission,
                x.Year,
                x.MileageKm,
                x.ElectricRangeKm,
                x.BatteryKwh,
                x.Horsepower,
                x.Kilowatts,
                x.HasTowHook,
                x.HasFourWheelDrive
            })
            .ToListAsync(ct);

        return Ok(new { items });
    }

    [Authorize]
    [HttpPost("{id:guid}/generate-description")]
    public async Task<ActionResult<object>> GenerateDescription([FromRoute] Guid id, CancellationToken ct)
    {
        var userId = GetUserId();
        var listing = await _db.CarListings.FirstOrDefaultAsync(x => x.Id == id, ct);
        if (listing is null) return NotFound();
        if (listing.SellerUserId != userId) return Forbid();

        var text = await _ai.GenerateDescriptionAsync(listing, ct);
        listing.Description = text;
        listing.UpdatedAtUtc = DateTime.UtcNow;
        await _db.SaveChangesAsync(ct);

        return Ok(new { description = text });
    }

    private Guid GetUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.Parse(sub!);
    }

    private static IQueryable<CarListing> ApplyCriteria(IQueryable<CarListing> q, ListingFilterCriteria criteria)
    {
        if (!string.IsNullOrWhiteSpace(criteria.Q))
        {
            var needle = criteria.Q.Trim();
            q = q.Where(x => (x.Make + " " + x.Model + " " + (x.Variant ?? "") + " " + (x.Title ?? "")).Contains(needle));
        }

        if (criteria.Makes is { Count: > 0 })
        {
            q = q.Where(x => criteria.Makes.Contains(x.Make));
        }

        if (criteria.Models is { Count: > 0 })
        {
            q = q.Where(x => criteria.Models.Contains(x.Model));
        }

        if (criteria.FuelTypes is { Count: > 0 })
        {
            q = q.Where(x => criteria.FuelTypes.Contains(x.FuelType));
        }

        if (criteria.Transmissions is { Count: > 0 })
        {
            q = q.Where(x => criteria.Transmissions.Contains(x.Transmission));
        }

        if (criteria.PriceMin is not null) q = q.Where(x => x.PriceDkk >= criteria.PriceMin);
        if (criteria.PriceMax is not null) q = q.Where(x => x.PriceDkk <= criteria.PriceMax);

        if (criteria.YearMin is not null) q = q.Where(x => x.Year >= criteria.YearMin);
        if (criteria.YearMax is not null) q = q.Where(x => x.Year <= criteria.YearMax);

        if (criteria.MileageMin is not null) q = q.Where(x => x.MileageKm >= criteria.MileageMin);
        if (criteria.MileageMax is not null) q = q.Where(x => x.MileageKm <= criteria.MileageMax);

        if (criteria.RangeMin is not null) q = q.Where(x => x.ElectricRangeKm >= criteria.RangeMin);
        if (criteria.RangeMax is not null) q = q.Where(x => x.ElectricRangeKm <= criteria.RangeMax);

        if (criteria.HorsepowerMin is not null) q = q.Where(x => x.Horsepower >= criteria.HorsepowerMin);
        if (criteria.HorsepowerMax is not null) q = q.Where(x => x.Horsepower <= criteria.HorsepowerMax);

        if (criteria.KilowattsMin is not null) q = q.Where(x => x.Kilowatts >= criteria.KilowattsMin);
        if (criteria.KilowattsMax is not null) q = q.Where(x => x.Kilowatts <= criteria.KilowattsMax);

        if (criteria.HasTowHook is not null) q = q.Where(x => x.HasTowHook == criteria.HasTowHook);
        if (criteria.HasFourWheelDrive is not null) q = q.Where(x => x.HasFourWheelDrive == criteria.HasFourWheelDrive);

        if (criteria.RequiredFeatures is { Count: > 0 })
        {
            foreach (var feature in criteria.RequiredFeatures)
            {
                if (!string.IsNullOrWhiteSpace(feature))
                {
                    q = q.Where(x => x.FeaturesJson.Contains('"' + feature + '"'));
                }
            }
        }

        if (criteria.CenterLat is not null && criteria.CenterLng is not null && criteria.RadiusKm is not null)
        {
            var lat = criteria.CenterLat.Value;
            var lng = criteria.CenterLng.Value;
            var degreeRadius = criteria.RadiusKm.Value / 111.0;

            q = q.Where(x => x.Latitude != null && x.Longitude != null)
                .Where(x => x.Latitude >= lat - degreeRadius && x.Latitude <= lat + degreeRadius)
                .Where(x => x.Longitude >= lng - degreeRadius && x.Longitude <= lng + degreeRadius);
        }

        return q;
    }
}
