using System.Security.Claims;
using Billister.Data;
using Billister.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Billister.Controllers;

[ApiController]
[Authorize]
[Route("api/favorites")]
public sealed class FavoritesController : ControllerBase
{
    private readonly BillisterDbContext _db;

    public FavoritesController(BillisterDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<ActionResult<object>> List(CancellationToken ct)
    {
        var userId = GetUserId();

        var items = await _db.Favorites
            .AsNoTracking()
            .Where(f => f.UserId == userId)
            .Join(_db.CarListings.AsNoTracking(), f => f.ListingId, l => l.Id, (f, l) => new
            {
                l.Id,
                l.Make,
                l.Model,
                l.Variant,
                l.PriceDkk,
                l.FuelType,
                l.Transmission,
                l.Year,
                l.MileageKm,
                l.CreatedAtUtc,
                favoritedAtUtc = f.CreatedAtUtc
            })
            .OrderByDescending(x => x.favoritedAtUtc)
            .Take(200)
            .ToListAsync(ct);

        return Ok(new { items });
    }

    [HttpPost("{listingId:guid}")]
    public async Task<ActionResult> Add([FromRoute] Guid listingId, CancellationToken ct)
    {
        var userId = GetUserId();

        var exists = await _db.CarListings.AnyAsync(x => x.Id == listingId, ct);
        if (!exists) return NotFound();

        var favorite = await _db.Favorites.FindAsync(new object[] { userId, listingId }, ct);
        if (favorite is not null) return NoContent();

        _db.Favorites.Add(new Favorite { UserId = userId, ListingId = listingId });

        var listing = await _db.CarListings.FirstOrDefaultAsync(x => x.Id == listingId, ct);
        if (listing is not null)
        {
            listing.FavoriteCount += 1;
        }

        await _db.SaveChangesAsync(ct);
        return NoContent();
    }

    [HttpDelete("{listingId:guid}")]
    public async Task<ActionResult> Remove([FromRoute] Guid listingId, CancellationToken ct)
    {
        var userId = GetUserId();

        var favorite = await _db.Favorites.FindAsync(new object[] { userId, listingId }, ct);
        if (favorite is null) return NoContent();

        _db.Favorites.Remove(favorite);

        var listing = await _db.CarListings.FirstOrDefaultAsync(x => x.Id == listingId, ct);
        if (listing is not null && listing.FavoriteCount > 0)
        {
            listing.FavoriteCount -= 1;
        }

        await _db.SaveChangesAsync(ct);
        return NoContent();
    }

    private Guid GetUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.Parse(sub!);
    }
}
