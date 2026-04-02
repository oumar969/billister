namespace Billister.Models;

public sealed class Order
{
    public Guid Id { get; set; }
    public Guid ListingId { get; set; }
    public Guid BuyerId { get; set; }
    public Guid SellerId { get; set; }

    public decimal Amount { get; set; } // i DKK
    public string Status { get; set; } = "pending"; // pending, paid, shipped, completed, cancelled
    public string? Invoice { get; set; } // File path or S3 key

    public DateTime CreatedAtUtc { get; set; }
    public DateTime? PaidAtUtc { get; set; }
    public DateTime? UpdatedAtUtc { get; set; }

    // Navigation properties
    public CarListing? Listing { get; set; }
    public ApplicationUser? Buyer { get; set; }
    public ApplicationUser? Seller { get; set; }
}

public sealed class Payment
{
    public Guid Id { get; set; }
    public Guid OrderId { get; set; }

    public decimal Amount { get; set; } // i DKK
    public string Provider { get; set; } = "stripe"; // stripe, mobilepay, etc
    public string ExternalPaymentId { get; set; } = string.Empty; // Stripe ID, etc
    public string Status { get; set; } = "pending"; // pending, processing, succeeded, failed

    public string? FailureReason { get; set; }

    public DateTime CreatedAtUtc { get; set; }
    public DateTime? CompletedAtUtc { get; set; }

    // Navigation property
    public Order? Order { get; set; }
}
