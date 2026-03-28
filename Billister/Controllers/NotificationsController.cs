using System.Security.Claims;
using Billister.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Billister.Controllers;

[ApiController]
[Authorize]
[Route("api/notifications")]
public sealed class NotificationsController : ControllerBase
{
    private readonly BillisterDbContext _db;

    public NotificationsController(BillisterDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<ActionResult<object>> List(CancellationToken ct)
    {
        var userId = GetUserId();

        var items = await (
            from n in _db.SearchMatchNotifications.AsNoTracking()
            where n.UserId == userId
            join s in _db.SavedSearches.AsNoTracking() on n.SavedSearchId equals s.Id into sj
            from s in sj.DefaultIfEmpty()
            orderby n.CreatedAtUtc descending
            select new
            {
                n.Id,
                n.SavedSearchId,
                savedSearchName = s != null ? s.Name : null,
                n.ListingId,
                n.Title,
                n.Body,
                n.CreatedAtUtc
            }
        )
        .Take(200)
        .ToListAsync(ct);

        return Ok(new { items });
    }

    [HttpDelete("{id:guid}")]
    public async Task<ActionResult> Delete([FromRoute] Guid id, CancellationToken ct)
    {
        var userId = GetUserId();

        var entity = await _db.SearchMatchNotifications.FirstOrDefaultAsync(
            x => x.Id == id && x.UserId == userId,
            ct);

        if (entity is null) return NoContent();

        _db.SearchMatchNotifications.Remove(entity);
        await _db.SaveChangesAsync(ct);
        return NoContent();
    }

    [HttpDelete]
    public async Task<ActionResult> Clear(CancellationToken ct)
    {
        var userId = GetUserId();

        var items = await _db.SearchMatchNotifications
            .Where(x => x.UserId == userId)
            .ToListAsync(ct);

        if (items.Count == 0) return NoContent();

        _db.SearchMatchNotifications.RemoveRange(items);
        await _db.SaveChangesAsync(ct);
        return NoContent();
    }

    private Guid GetUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.Parse(sub!);
    }
}
