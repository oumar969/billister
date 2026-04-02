namespace Billister.Models;

public sealed class ChatMessage
{
    public Guid Id { get; set; }
    public Guid ChatThreadId { get; set; }
    public Guid SenderId { get; set; }
    public Guid ReceiverId { get; set; }

    public string Content { get; set; } = string.Empty;
    public bool IsRead { get; set; }

    public DateTime CreatedAtUtc { get; set; }
    public DateTime? ReadAtUtc { get; set; }

    // Navigation properties
    public ChatThread? ChatThread { get; set; }
    public ApplicationUser? Sender { get; set; }
    public ApplicationUser? Receiver { get; set; }
}
