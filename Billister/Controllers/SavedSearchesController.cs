using System.Security.Claims;
using Billister.Data;
using Billister.Contracts;
using Billister.Models;
using Billister.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Billister.Controllers;

[ApiController]
[Authorize]
[Route("api/saved-searches")]
public sealed class SavedSearchesController : ControllerBase
{
    private readonly BillisterDbContext _db;

    public SavedSearchesController(BillisterDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<ActionResult<object>> List(CancellationToken ct)
    {
        var userId = GetUserId();

        var items = await _db.SavedSearches
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .OrderByDescending(x => x.CreatedAtUtc)
            .Take(200)
            .Select(x => new { x.Id, x.Name, x.CriteriaJson, x.CreatedAtUtc, x.UpdatedAtUtc, x.LastNotifiedAtUtc })
            .ToListAsync(ct);

        return Ok(new { items });
    }

    [HttpPost]
    public async Task<ActionResult<object>> Create([FromBody] ApiDtos.SavedSearches.CreateSavedSearchRequest req, CancellationToken ct)
    {
        var userId = GetUserId();

        if (!ListingFilterCriteriaJson.TryParse(req.CriteriaJson, out _, out var normalizedJson))
        {
            return BadRequest(new { error = "CriteriaJson must be valid ListingFilterCriteria JSON" });
        }

        var entity = new SavedSearch
        {
            UserId = userId,
            Name = req.Name,
            CriteriaJson = normalizedJson
        };

        _db.SavedSearches.Add(entity);
        await _db.SaveChangesAsync(ct);

        return CreatedAtAction(nameof(GetById), new { id = entity.Id }, new { entity.Id });
    }

    // Flutter-friendly: send criteria as an object (no JSON string)
    [HttpPost("from-criteria")]
    public async Task<ActionResult<object>> CreateFromCriteria([FromBody] ApiDtos.SavedSearches.CreateSavedSearchFromCriteriaRequest req, CancellationToken ct)
    {
        var userId = GetUserId();

        var normalizedJson = ListingFilterCriteriaJson.Normalize(req.Criteria);

        var entity = new SavedSearch
        {
            UserId = userId,
            Name = req.Name,
            CriteriaJson = normalizedJson
        };

        _db.SavedSearches.Add(entity);
        await _db.SaveChangesAsync(ct);

        return CreatedAtAction(nameof(GetById), new { id = entity.Id }, new { entity.Id });
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<object>> GetById([FromRoute] Guid id, CancellationToken ct)
    {
        var userId = GetUserId();
        var entity = await _db.SavedSearches.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId, ct);
        if (entity is null) return NotFound();

        return Ok(new { entity.Id, entity.Name, entity.CriteriaJson, entity.CreatedAtUtc, entity.UpdatedAtUtc, entity.LastNotifiedAtUtc });
    }

    [HttpPatch("{id:guid}")]
    public async Task<ActionResult> Update([FromRoute] Guid id, [FromBody] ApiDtos.SavedSearches.UpdateSavedSearchRequest req, CancellationToken ct)
    {
        var userId = GetUserId();
        var entity = await _db.SavedSearches.FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId, ct);
        if (entity is null) return NotFound();

        if (req.Name is not null) entity.Name = req.Name;
        if (req.CriteriaJson is not null)
        {
            if (!ListingFilterCriteriaJson.TryParse(req.CriteriaJson, out _, out var normalizedJson))
            {
                return BadRequest(new { error = "CriteriaJson must be valid ListingFilterCriteria JSON" });
            }

            entity.CriteriaJson = normalizedJson;
        }
        entity.UpdatedAtUtc = DateTime.UtcNow;

        await _db.SaveChangesAsync(ct);
        return NoContent();
    }

    [HttpDelete("{id:guid}")]
    public async Task<ActionResult> Delete([FromRoute] Guid id, CancellationToken ct)
    {
        var userId = GetUserId();
        var entity = await _db.SavedSearches.FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId, ct);
        if (entity is null) return NoContent();

        _db.SavedSearches.Remove(entity);
        await _db.SaveChangesAsync(ct);
        return NoContent();
    }

    private Guid GetUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.Parse(sub!);
    }
}
