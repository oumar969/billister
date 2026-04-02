using Billister.Data;
using Billister.Models;
using Microsoft.EntityFrameworkCore;

namespace Billister.Services;

public sealed class ChatService : IChatService
{
    private readonly BillisterDbContext _db;

    public ChatService(BillisterDbContext db)
    {
        _db = db;
    }

    public async Task<ChatMessage> SendMessageAsync(Guid threadId, Guid senderId, string content, CancellationToken ct = default)
    {
        // Validate thread exists and user is participant
        var thread = await _db.ChatThreads
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == threadId, ct);

        if (thread is null)
            throw new InvalidOperationException("Chat thread not found.");

        if (thread.BuyerId != senderId && thread.SellerId != senderId)
            throw new InvalidOperationException("User is not a participant in this thread.");

        var receiverId = thread.BuyerId == senderId ? thread.SellerId : thread.BuyerId;

        var message = new ChatMessage
        {
            ChatThreadId = threadId,
            SenderId = senderId,
            ReceiverId = receiverId,
            Content = content,
            IsRead = false,
            CreatedAtUtc = DateTime.UtcNow
        };

        _db.ChatMessages.Add(message);
        await _db.SaveChangesAsync(ct);

        // Reload with navigation properties
        await _db.Entry(message).Reference(x => x.ChatThread).LoadAsync(ct);
        await _db.Entry(message).Reference(x => x.Sender).LoadAsync(ct);

        return message;
    }

    public async Task<List<ChatMessage>> GetMessagesAsync(Guid threadId, int skip = 0, int take = 50, CancellationToken ct = default)
    {
        var messages = await _db.ChatMessages
            .Where(x => x.ChatThreadId == threadId)
            .OrderByDescending(x => x.CreatedAtUtc)
            .Skip(skip)
            .Take(take)
            .Include(x => x.Sender)
            .Include(x => x.Receiver)
            .ToListAsync(ct);

        // Reverse to get chronological order (oldest first)
        messages.Reverse();
        return messages;
    }

    public async Task MarkMessageAsReadAsync(Guid messageId, CancellationToken ct = default)
    {
        var message = await _db.ChatMessages
            .FirstOrDefaultAsync(x => x.Id == messageId, ct);

        if (message is not null && !message.IsRead)
        {
            message.IsRead = true;
            message.ReadAtUtc = DateTime.UtcNow;
            await _db.SaveChangesAsync(ct);
        }
    }

    public async Task MarkThreadAsReadAsync(Guid threadId, Guid receiverId, CancellationToken ct = default)
    {
        var unreadMessages = await _db.ChatMessages
            .Where(x => x.ChatThreadId == threadId && x.ReceiverId == receiverId && !x.IsRead)
            .ToListAsync(ct);

        foreach (var message in unreadMessages)
        {
            message.IsRead = true;
            message.ReadAtUtc = DateTime.UtcNow;
        }

        if (unreadMessages.Count > 0)
            await _db.SaveChangesAsync(ct);
    }

    public async Task<int> GetUnreadCountAsync(Guid userId, CancellationToken ct = default)
    {
        return await _db.ChatMessages
            .Where(x => x.ReceiverId == userId && !x.IsRead)
            .CountAsync(ct);
    }

    public async Task<Dictionary<Guid, int>> GetUnreadCountPerThreadAsync(Guid userId, CancellationToken ct = default)
    {
        var result = await _db.ChatMessages
            .Where(x => x.ReceiverId == userId && !x.IsRead)
            .GroupBy(x => x.ChatThreadId)
            .Select(g => new { threadId = g.Key, count = g.Count() })
            .ToListAsync(ct);

        return result.ToDictionary(x => x.threadId, x => x.count);
    }
}
