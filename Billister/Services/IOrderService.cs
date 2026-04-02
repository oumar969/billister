using Billister.Models;

namespace Billister.Services;

public interface IOrderService
{
    Task<Order> CreateOrderAsync(Guid listingId, Guid buyerId, Guid sellerId, decimal amount);

    Task<Order?> GetOrderAsync(Guid orderId);

    Task<List<Order>> GetBuyerOrdersAsync(Guid buyerId);

    Task<List<Order>> GetSellerOrdersAsync(Guid sellerId);

    Task<bool> UpdateOrderStatusAsync(Guid orderId, string status);
}

public interface IPaymentService
{
    /// <summary>
    /// Initialize payment (create Stripe session, reserve payment, etc)
    /// </summary>
    Task<Payment> InitiatePaymentAsync(Guid orderId, decimal amount);

    /// <summary>
    /// Confirm payment was successful
    /// </summary>
    Task<bool> ConfirmPaymentAsync(Guid paymentId, string externalPaymentId);

    /// <summary>
    /// Mark payment as failed
    /// </summary>
    Task<bool> FailPaymentAsync(Guid paymentId, string reason);

    /// <summary>
    /// Get payment by order
    /// </summary>
    Task<Payment?> GetPaymentByOrderAsync(Guid orderId);
}
