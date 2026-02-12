namespace Billister.Models;

public sealed class ChatThread
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid ListingId { get; set; }
    public Guid BuyerId { get; set; }
    public Guid SellerId { get; set; }

    // Firebase path suggestion; messages live in Firebase
    public string FirebaseThreadPath { get; set; } = string.Empty;

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}
