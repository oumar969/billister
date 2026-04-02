using Billister.Contracts;
using Billister.Data;
using Billister.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using System.Text.Json;
using Stripe;
using Stripe.Checkout;

namespace Billister.Controllers;

[ApiController]
[Route("api/payments")]
public sealed class PaymentsController : ControllerBase
{
    private readonly IPaymentService _paymentService;
    private readonly BillisterDbContext _db;
    private readonly IConfiguration _config;
    private readonly ILogger<PaymentsController> _logger;

    public PaymentsController(IPaymentService paymentService, BillisterDbContext db, IConfiguration config, ILogger<PaymentsController> logger)
    {
        _paymentService = paymentService;
        _db = db;
        _config = config;
        _logger = logger;
    }

    [Authorize]
    [HttpPost("initiate")]
    public async Task<IActionResult> InitiatePayment(
        [FromBody] ApiDtos.Payments.InitiatePaymentRequest req)
    {
        if (req.OrderId == Guid.Empty || req.Amount <= 0)
            return BadRequest(new { error = "Invalid order or amount" });

        try
        {
            var payment = await _paymentService.InitiatePaymentAsync(req.OrderId, req.Amount);

            // Get the Stripe PaymentIntent to return client secret
            if (!string.IsNullOrEmpty(payment.ExternalPaymentId))
            {
                var service = new PaymentIntentService();
                var intent = await service.GetAsync(payment.ExternalPaymentId);

                return Ok(new
                {
                    paymentId = payment.Id,
                    stripePaymentIntentId = intent.Id,
                    clientSecret = intent.ClientSecret,
                    amount = payment.Amount,
                    status = payment.Status,
                    message = "Betaling initialiseret. Fortsæt til betalingsudbyder"
                });
            }

            return Ok(new
            {
                paymentId = payment.Id,
                amount = payment.Amount,
                status = payment.Status,
                message = "Betaling initialiseret"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error initiating payment for order {OrderId}", req.OrderId);
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPost("confirm")]
    public async Task<IActionResult> ConfirmPayment(
        [FromBody] ApiDtos.Payments.ConfirmPaymentRequest req)
    {
        if (req.PaymentId == Guid.Empty || string.IsNullOrEmpty(req.StripeSessionId))
            return BadRequest(new { error = "Payment ID og Session ID er påkrævet" });

        try
        {
            var success = await _paymentService.ConfirmPaymentAsync(req.PaymentId, req.StripeSessionId);
            if (!success)
                return BadRequest(new { error = "Betaling kunne ikke bekræftes" });

            // Update the order listing to mark it as sold
            var payment = await _db.Payments.Include(p => p.Order).FirstOrDefaultAsync(p => p.Id == req.PaymentId);
            if (payment?.Order is not null)
            {
                var listing = await _db.CarListings.FirstOrDefaultAsync(l => l.Id == payment.Order.ListingId);
                if (listing is not null)
                {
                    listing.IsSold = true;
                    await _db.SaveChangesAsync();
                }
            }

            return Ok(new { message = "Betaling bekræftet. Tak!" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error confirming payment {PaymentId}", req.PaymentId);
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Responds to Stripe webhooks to confirm payments and update order statuses.
    /// Verifies webhook signature before processing.
    /// </summary>
    [HttpPost("webhook/stripe")]
    public async Task<IActionResult> HandleStripeWebhook()
    {
        var json = await new StreamReader(HttpContext.Request.Body).ReadToEndAsync();
        var webhookSecret = _config["Stripe:WebhookSecret"];

        try
        {
            var stripeEvent = EventUtility.ConstructEvent(
                json,
                Request.Headers["Stripe-Signature"],
                webhookSecret,
                throwOnApiVersionMismatch: false
            );

            _logger.LogInformation($"Stripe webhook event: {stripeEvent.Type}");

            switch (stripeEvent.Type)
            {
                case "payment_intent.succeeded":
                    await HandlePaymentIntentSucceeded(stripeEvent.Data.Object as PaymentIntent);
                    break;

                case "payment_intent.payment_failed":
                    await HandlePaymentIntentFailed(stripeEvent.Data.Object as PaymentIntent);
                    break;

                case "charge.refunded":
                    _logger.LogInformation($"Charge refunded: {(stripeEvent.Data.Object as Charge)?.Id}");
                    break;
            }

            return Ok();
        }
        catch (StripeException e)
        {
            _logger.LogError(e, "Stripe webhook signature verification failed");
            return BadRequest();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing Stripe webhook");
            return StatusCode(500);
        }
    }

    private async Task HandlePaymentIntentSucceeded(PaymentIntent? intent)
    {
        if (intent?.Metadata is null)
            return;

        if (!intent.Metadata.TryGetValue("orderId", out var orderIdStr) || !Guid.TryParse(orderIdStr, out var orderId))
        {
            _logger.LogWarning($"PaymentIntent {intent.Id} missing or invalid orderId metadata");
            return;
        }

        // Find payment by external ID and confirm it
        var payment = await _db.Payments.Include(p => p.Order)
            .FirstOrDefaultAsync(p => p.ExternalPaymentId == intent.Id);

        if (payment is not null)
        {
            var success = await _paymentService.ConfirmPaymentAsync(payment.Id, intent.Id);
            if (success)
            {
                _logger.LogInformation($"Payment {payment.Id} confirmed via webhook for order {orderId}");

                // Mark listing as sold
                if (payment.Order is not null)
                {
                    var listing = await _db.CarListings.FirstOrDefaultAsync(l => l.Id == payment.Order.ListingId);
                    if (listing is not null)
                    {
                        listing.IsSold = true;
                        await _db.SaveChangesAsync();
                    }
                }
            }
        }
        else
        {
            _logger.LogWarning($"No payment found for Stripe PaymentIntent {intent.Id}");
        }
    }

    private async Task HandlePaymentIntentFailed(PaymentIntent? intent)
    {
        if (intent?.Metadata is null)
            return;

        if (!intent.Metadata.TryGetValue("orderId", out var orderIdStr) || !Guid.TryParse(orderIdStr, out var orderId))
        {
            _logger.LogWarning($"PaymentIntent {intent.Id} missing or invalid orderId metadata");
            return;
        }

        var payment = await _db.Payments
            .FirstOrDefaultAsync(p => p.ExternalPaymentId == intent.Id);

        if (payment is not null)
        {
            var reason = intent.LastPaymentError?.Message ?? "Payment failed";
            await _paymentService.FailPaymentAsync(payment.Id, reason);
            _logger.LogInformation($"Payment {payment.Id} failed via webhook: {reason}");
        }
    }

    /// <summary>
    /// Gets payment details by ID with authorization check.
    /// </summary>
    [Authorize]
    [HttpGet("{paymentId}")]
    public async Task<IActionResult> GetPayment([FromRoute] Guid paymentId, CancellationToken ct = default)
    {
        try
        {
            var payment = await _db.Payments
                .Include(p => p.Order)
                .FirstOrDefaultAsync(p => p.Id == paymentId, ct);

            if (payment is null)
                return NotFound(new { error = "Betaling ikke fundet" });

            // Authorization: buyer or seller of the order can view payment
            var userId = GetUserId();
            var order = payment.Order;

            if (order is null || (order.BuyerId != userId && order.SellerId != userId))
                return Forbid();

            var dto = new ApiDtos.Payments.PaymentDto(
                payment.Id,
                payment.OrderId,
                payment.Amount,
                payment.Status,
                payment.Provider,
                payment.CreatedAtUtc,
                payment.CompletedAtUtc);

            return Ok(dto);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting payment {PaymentId}", paymentId);
            return StatusCode(500, new { error = "Der opstod en fejl" });
        }
    }

    private Guid GetUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.Parse(sub!);
    }
}
