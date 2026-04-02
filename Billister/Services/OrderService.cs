using Billister.Data;
using Billister.Models;
using Microsoft.EntityFrameworkCore;

namespace Billister.Services;

public sealed class OrderService : IOrderService
{
    private readonly BillisterDbContext _db;

    public OrderService(BillisterDbContext db)
    {
        _db = db;
    }

    public async Task<Order> CreateOrderAsync(Guid listingId, Guid buyerId, Guid sellerId, decimal amount)
    {
        if (amount <= 0)
            throw new ArgumentException("Amount must be greater than 0");

        var order = new Order
        {
            Id = Guid.NewGuid(),
            ListingId = listingId,
            BuyerId = buyerId,
            SellerId = sellerId,
            Amount = amount,
            Status = "pending",
            CreatedAtUtc = DateTime.UtcNow
        };

        _db.Orders.Add(order);
        await _db.SaveChangesAsync();

        return order;
    }

    public async Task<Order?> GetOrderAsync(Guid orderId)
    {
        return await _db.Orders
            .Include(o => o.Listing)
            .Include(o => o.Buyer)
            .Include(o => o.Seller)
            .FirstOrDefaultAsync(o => o.Id == orderId);
    }

    public async Task<List<Order>> GetBuyerOrdersAsync(Guid buyerId)
    {
        return await _db.Orders
            .Where(o => o.BuyerId == buyerId)
            .OrderByDescending(o => o.CreatedAtUtc)
            .Include(o => o.Listing)
            .Include(o => o.Seller)
            .ToListAsync();
    }

    public async Task<List<Order>> GetSellerOrdersAsync(Guid sellerId)
    {
        return await _db.Orders
            .Where(o => o.SellerId == sellerId)
            .OrderByDescending(o => o.CreatedAtUtc)
            .Include(o => o.Listing)
            .Include(o => o.Buyer)
            .ToListAsync();
    }

    public async Task<bool> UpdateOrderStatusAsync(Guid orderId, string status)
    {
        var order = await _db.Orders.FirstOrDefaultAsync(o => o.Id == orderId);
        if (order == null)
            return false;

        order.Status = status;
        order.UpdatedAtUtc = DateTime.UtcNow;

        if (status == "paid")
            order.PaidAtUtc = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        return true;
    }
}

public sealed class PaymentService : IPaymentService
{
    private readonly BillisterDbContext _db;

    public PaymentService(BillisterDbContext db)
    {
        _db = db;
    }

    public async Task<Payment> InitiatePaymentAsync(Guid orderId, decimal amount)
    {
        if (amount <= 0)
            throw new ArgumentException("Amount must be greater than 0");

        var order = await _db.Orders.FirstOrDefaultAsync(o => o.Id == orderId);
        if (order == null)
            throw new ArgumentException("Order not found");

        // Check if payment already exists
        var existingPayment = await _db.Payments.FirstOrDefaultAsync(p => p.OrderId == orderId);
        if (existingPayment != null)
            return existingPayment;

        var payment = new Payment
        {
            Id = Guid.NewGuid(),
            OrderId = orderId,
            Amount = amount,
            Status = "pending",
            CreatedAtUtc = DateTime.UtcNow
        };

        _db.Payments.Add(payment);
        await _db.SaveChangesAsync();

        return payment;
    }

    public async Task<bool> ConfirmPaymentAsync(Guid paymentId, string externalPaymentId)
    {
        var payment = await _db.Payments
            .Include(p => p.Order)
            .FirstOrDefaultAsync(p => p.Id == paymentId);

        if (payment == null)
            return false;

        payment.Status = "succeeded";
        payment.ExternalPaymentId = externalPaymentId;
        payment.CompletedAtUtc = DateTime.UtcNow;

        // Update order status to paid
        if (payment.Order != null)
        {
            payment.Order.Status = "paid";
            payment.Order.PaidAtUtc = DateTime.UtcNow;
            payment.Order.UpdatedAtUtc = DateTime.UtcNow;
        }

        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> FailPaymentAsync(Guid paymentId, string reason)
    {
        var payment = await _db.Payments.FirstOrDefaultAsync(p => p.Id == paymentId);
        if (payment == null)
            return false;

        payment.Status = "failed";
        payment.FailureReason = reason;
        payment.CompletedAtUtc = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<Payment?> GetPaymentByOrderAsync(Guid orderId)
    {
        return await _db.Payments
            .Include(p => p.Order)
            .FirstOrDefaultAsync(p => p.OrderId == orderId);
    }
}
