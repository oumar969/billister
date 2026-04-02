using Billister.Models;

namespace Billister.Services;

public interface IChatService
{
    /// <summary>
    /// Sends a message within a chat thread.
    /// </summary>
    Task<ChatMessage> SendMessageAsync(Guid threadId, Guid senderId, string content, CancellationToken ct = default);

    /// <summary>
    /// Gets all messages in a chat thread.
    /// </summary>
    Task<List<ChatMessage>> GetMessagesAsync(Guid threadId, int skip = 0, int take = 50, CancellationToken ct = default);

    /// <summary>
    /// Marks a message as read.
    /// </summary>
    Task MarkMessageAsReadAsync(Guid messageId, CancellationToken ct = default);

    /// <summary>
    /// Marks all messages in a thread as read for the receiver.
    /// </summary>
    Task MarkThreadAsReadAsync(Guid threadId, Guid receiverId, CancellationToken ct = default);

    /// <summary>
    /// Gets the count of unread messages for a user across all threads.
    /// </summary>
    Task<int> GetUnreadCountAsync(Guid userId, CancellationToken ct = default);

    /// <summary>
    /// Gets unread count per thread for a user.
    /// </summary>
    Task<Dictionary<Guid, int>> GetUnreadCountPerThreadAsync(Guid userId, CancellationToken ct = default);
}
