using Billister.Data;
using Billister.Models;
using Microsoft.EntityFrameworkCore;
using Stripe;

namespace Billister.Services;

public sealed class StripePaymentService : IPaymentService
{
    private readonly BillisterDbContext _db;
    private readonly IConfiguration _config;
    private readonly ILogger<StripePaymentService> _logger;

    public StripePaymentService(BillisterDbContext db, IConfiguration config, ILogger<StripePaymentService> logger)
    {
        _db = db;
        _config = config;
        _logger = logger;
    }

    public async Task<Payment> InitiatePaymentAsync(Guid orderId, decimal amount)
    {
        if (amount <= 0)
            throw new ArgumentException("Amount must be greater than 0");

        var order = await _db.Orders.FirstOrDefaultAsync(o => o.Id == orderId);
        if (order == null)
            throw new ArgumentException("Order not found");

        // Check if payment already exists
        var existingPayment = await _db.Payments.FirstOrDefaultAsync(p => p.OrderId == orderId && p.Status != "failed");
        if (existingPayment != null)
            return existingPayment;

        try
        {
            // Create Stripe Payment Intent
            var options = new PaymentIntentCreateOptions
            {
                Amount = (long)(amount * 100), // Convert to cents
                Currency = "dkk",
                PaymentMethodTypes = new List<string> { "card" },
                Metadata = new Dictionary<string, string>
                {
                    { "orderId", orderId.ToString() },
                    { "buyerId", order.BuyerId.ToString() },
                    { "sellerId", order.SellerId.ToString() },
                },
                StatementDescriptor = "Billister Marketplace",
            };

            var service = new PaymentIntentService();
            var paymentIntent = await service.CreateAsync(options);

            var payment = new Payment
            {
                Id = Guid.NewGuid(),
                OrderId = orderId,
                Amount = amount,
                Status = "pending",
                Provider = "stripe",
                ExternalPaymentId = paymentIntent.Id,
                CreatedAtUtc = DateTime.UtcNow
            };

            _db.Payments.Add(payment);
            await _db.SaveChangesAsync();

            _logger.LogInformation($"Created Stripe PaymentIntent {paymentIntent.Id} for order {orderId}");

            return payment;
        }
        catch (StripeException e)
        {
            _logger.LogError(e, $"Stripe error creating payment intent for order {orderId}");
            throw new InvalidOperationException($"Failed to create payment: {e.Message}");
        }
    }

    public async Task<bool> ConfirmPaymentAsync(Guid paymentId, string externalPaymentId)
    {
        try
        {
            var payment = await _db.Payments
                .Include(p => p.Order)
                .FirstOrDefaultAsync(p => p.Id == paymentId);

            if (payment == null)
                return false;

            // Verify Stripe PaymentIntent status
            var service = new PaymentIntentService();
            var paymentIntent = await service.GetAsync(externalPaymentId);

            if (paymentIntent.Status != "succeeded")
            {
                _logger.LogWarning($"PaymentIntent {externalPaymentId} status is {paymentIntent.Status}, not succeeded");
                payment.Status = "failed";
                payment.FailureReason = $"Payment intent status: {paymentIntent.Status}";
                payment.CompletedAtUtc = DateTime.UtcNow;
                await _db.SaveChangesAsync();
                return false;
            }

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

            _logger.LogInformation($"Payment {paymentId} confirmed for order {payment.OrderId}");

            return true;
        }
        catch (StripeException e)
        {
            _logger.LogError(e, $"Stripe error confirming payment {paymentId}");
            return false;
        }
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

        _logger.LogInformation($"Payment {paymentId} marked as failed: {reason}");

        return true;
    }

    public async Task<Payment?> GetPaymentByOrderAsync(Guid orderId)
    {
        return await _db.Payments
            .Include(p => p.Order)
            .FirstOrDefaultAsync(p => p.OrderId == orderId);
    }
}
