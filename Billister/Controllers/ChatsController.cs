using System.Security.Claims;
using Billister.Contracts;
using Billister.Data;
using Billister.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Billister.Controllers;

[ApiController]
[Authorize]
[Route("api/chats")]
public sealed class ChatsController : ControllerBase
{
    private readonly BillisterDbContext _db;

    public ChatsController(BillisterDbContext db)
    {
        _db = db;
    }

    [HttpPost("start")]
    public async Task<ActionResult<object>> Start([FromBody] ApiDtos.Chats.StartChatRequest req, CancellationToken ct)
    {
        var buyerId = GetUserId();

        var listing = await _db.CarListings.AsNoTracking().FirstOrDefaultAsync(x => x.Id == req.ListingId, ct);
        if (listing is null) return NotFound();

        var sellerId = listing.SellerUserId;
        if (sellerId == buyerId) return BadRequest(new { error = "cannot chat with yourself" });

        var existing = await _db.ChatThreads
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.ListingId == req.ListingId && x.BuyerId == buyerId && x.SellerId == sellerId, ct);

        if (existing is not null)
        {
            return Ok(new { existing.Id, existing.FirebaseThreadPath });
        }

        // Messages live in Firebase; this is just a stable thread id + path convention.
        var thread = new ChatThread
        {
            ListingId = req.ListingId,
            BuyerId = buyerId,
            SellerId = sellerId,
            FirebaseThreadPath = $"threads/{req.ListingId}/{buyerId}_{sellerId}".ToLowerInvariant()
        };

        _db.ChatThreads.Add(thread);
        await _db.SaveChangesAsync(ct);

        return Ok(new { thread.Id, thread.FirebaseThreadPath });
    }

    private Guid GetUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.Parse(sub!);
    }
}
