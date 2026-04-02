using System.Security.Claims;
using Billister.Contracts;
using Billister.Data;
using Billister.Models;
using Billister.Services;
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
    private readonly IChatService _chatService;

    public ChatsController(BillisterDbContext db, IChatService chatService)
    {
        _db = db;
        _chatService = chatService;
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

    /// <summary>
    /// Sends a message in a chat thread.
    /// </summary>
    [HttpPost("{threadId}/messages")]
    public async Task<ActionResult<ApiDtos.Chats.ChatMessageDto>> SendMessage(
        Guid threadId,
        [FromBody] ApiDtos.Chats.SendMessageRequest req,
        CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(req.Content) || req.Content.Length > 5000)
            return BadRequest(new { error = "Besked skal være 1-5000 tegn" });

        var userId = GetUserId();
        var thread = await _db.ChatThreads.AsNoTracking().FirstOrDefaultAsync(x => x.Id == threadId, ct);

        if (thread is null)
            return NotFound(new { error = "Chat-tråd ikke fundet" });

        if (thread.BuyerId != userId && thread.SellerId != userId)
            return Forbid();

        try
        {
            var message = await _chatService.SendMessageAsync(threadId, userId, req.Content.Trim(), ct);

            var dto = new ApiDtos.Chats.ChatMessageDto(
                message.Id,
                message.ChatThreadId,
                message.SenderId,
                message.Sender?.UserName ?? "",
                message.Content,
                message.IsRead,
                message.CreatedAtUtc,
                message.ReadAtUtc);

            return CreatedAtAction("GetMessage", new { threadId = threadId, messageId = message.Id }, dto);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Gets messages in a chat thread (paginated, newest first).
    /// </summary>
    [HttpGet("{threadId}/messages")]
    public async Task<ActionResult<List<ApiDtos.Chats.ChatMessageDto>>> GetMessages(
        Guid threadId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        CancellationToken ct = default)
    {
        if (page < 1 || pageSize < 1 || pageSize > 100)
            return BadRequest(new { error = "Ugyldige sideparametre" });

        var userId = GetUserId();
        var thread = await _db.ChatThreads.AsNoTracking().FirstOrDefaultAsync(x => x.Id == threadId, ct);

        if (thread is null)
            return NotFound();

        if (thread.BuyerId != userId && thread.SellerId != userId)
            return Forbid();

        var skip = (page - 1) * pageSize;
        var messages = await _chatService.GetMessagesAsync(threadId, skip, pageSize, ct);

        var dtos = messages.Select(m => new ApiDtos.Chats.ChatMessageDto(
            m.Id,
            m.ChatThreadId,
            m.SenderId,
            m.Sender?.UserName ?? "",
            m.Content,
            m.IsRead,
            m.CreatedAtUtc,
            m.ReadAtUtc)).ToList();

        return Ok(dtos);
    }

    /// <summary>
    /// Marks a specific message as read.
    /// </summary>
    [HttpPut("messages/{messageId}/mark-read")]
    public async Task<IActionResult> MarkMessageAsRead(Guid messageId, CancellationToken ct)
    {
        var userId = GetUserId();
        var message = await _db.ChatMessages.AsNoTracking().FirstOrDefaultAsync(x => x.Id == messageId, ct);

        if (message is null)
            return NotFound();

        if (message.ReceiverId != userId)
            return Forbid();

        await _chatService.MarkMessageAsReadAsync(messageId, ct);
        return NoContent();
    }

    /// <summary>
    /// Marks all messages in a thread as read for the current user.
    /// </summary>
    [HttpPut("{threadId}/mark-all-read")]
    public async Task<IActionResult> MarkThreadAsRead(Guid threadId, CancellationToken ct)
    {
        var userId = GetUserId();
        var thread = await _db.ChatThreads.AsNoTracking().FirstOrDefaultAsync(x => x.Id == threadId, ct);

        if (thread is null)
            return NotFound();

        if (thread.BuyerId != userId && thread.SellerId != userId)
            return Forbid();

        await _chatService.MarkThreadAsReadAsync(threadId, userId, ct);
        return NoContent();
    }

    /// <summary>
    /// Gets unread message count for the current user.
    /// </summary>
    [HttpGet("unread-count")]
    public async Task<ActionResult<ApiDtos.Chats.UnreadCountDto>> GetUnreadCount(CancellationToken ct)
    {
        var userId = GetUserId();
        var total = await _chatService.GetUnreadCountAsync(userId, ct);
        var perThread = await _chatService.GetUnreadCountPerThreadAsync(userId, ct);

        return Ok(new ApiDtos.Chats.UnreadCountDto(total, perThread));
    }

    /// <summary>
    /// Seller helper: returns inquiry counts per listing for the current user.
    /// "Inquiry" is a ChatThread record (messages live in Firebase).
    /// </summary>
    [HttpGet("seller-inquiries")]
    public async Task<ActionResult<object>> SellerInquiries(CancellationToken ct)
    {
        var sellerId = GetUserId();

        var items = await _db.ChatThreads
            .AsNoTracking()
            .Where(t => t.SellerId == sellerId)
            .GroupBy(t => t.ListingId)
            .Select(g => new
            {
                listingId = g.Key,
                threadCount = g.Count(),
                lastInquiryAtUtc = g.Max(x => x.CreatedAtUtc)
            })
            .ToListAsync(ct);

        return Ok(new { items });
    }

    private Guid GetUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.Parse(sub!);
    }
}
