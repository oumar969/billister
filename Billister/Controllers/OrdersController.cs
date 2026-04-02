using Billister.Contracts;
using Billister.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Billister.Controllers;

[ApiController]
[Route("api/orders")]
public sealed class OrdersController : ControllerBase
{
    private readonly IOrderService _orderService;

    public OrdersController(IOrderService orderService)
    {
        _orderService = orderService;
    }

    [Authorize]
    [HttpPost("create")]
    public async Task<IActionResult> CreateOrder(
        [FromBody] ApiDtos.Orders.CreateOrderRequest req)
    {
        if (req.ListingId == Guid.Empty || req.SellerId == Guid.Empty || req.Amount <= 0)
            return BadRequest(new { error = "Ugyldige parametre" });

        var buyerIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(buyerIdClaim) || !Guid.TryParse(buyerIdClaim, out var buyerId))
            return Unauthorized(new { error = "Bruger ikke fundet" });

        try
        {
            var order = await _orderService.CreateOrderAsync(
                req.ListingId,
                buyerId,
                req.SellerId,
                req.Amount);

            return Ok(new { orderId = order.Id, status = order.Status });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [Authorize]
    [HttpGet("{orderId}")]
    public async Task<IActionResult> GetOrder([FromRoute] Guid orderId)
    {
        if (orderId == Guid.Empty)
            return BadRequest(new { error = "Order ID er påkrævet" });

        var order = await _orderService.GetOrderAsync(orderId);
        if (order == null)
            return NotFound(new { error = "Ordre ikke fundet" });

        var orderDto = new ApiDtos.Orders.OrderDto(
            order.Id,
            order.ListingId,
            order.Status,
            order.Amount,
            order.CreatedAtUtc,
            order.PaidAtUtc,
            order.UpdatedAtUtc);

        return Ok(orderDto);
    }

    [Authorize]
    [HttpGet("buyer/my-orders")]
    public async Task<IActionResult> GetMyOrders()
    {
        var buyerIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(buyerIdClaim) || !Guid.TryParse(buyerIdClaim, out var buyerId))
            return Unauthorized(new { error = "Bruger ikke fundet" });

        var orders = await _orderService.GetBuyerOrdersAsync(buyerId);

        var orderDtos = orders.Select(o => new ApiDtos.Orders.OrderDto(
            o.Id,
            o.ListingId,
            o.Status,
            o.Amount,
            o.CreatedAtUtc,
            o.PaidAtUtc,
            o.UpdatedAtUtc)).ToList();

        return Ok(orderDtos);
    }

    [Authorize]
    [HttpGet("seller/sales")]
    public async Task<IActionResult> GetSellerOrders()
    {
        var sellerIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(sellerIdClaim) || !Guid.TryParse(sellerIdClaim, out var sellerId))
            return Unauthorized(new { error = "Bruger ikke fundet" });

        var orders = await _orderService.GetSellerOrdersAsync(sellerId);

        var orderDtos = orders.Select(o => new ApiDtos.Orders.OrderDto(
            o.Id,
            o.ListingId,
            o.Status,
            o.Amount,
            o.CreatedAtUtc,
            o.PaidAtUtc,
            o.UpdatedAtUtc)).ToList();

        return Ok(orderDtos);
    }

    [Authorize]
    [HttpPut("{orderId}/mark-shipped")]
    public async Task<IActionResult> MarkShipped([FromRoute] Guid orderId)
    {
        if (orderId == Guid.Empty)
            return BadRequest(new { error = "Order ID er påkrævet" });

        var success = await _orderService.UpdateOrderStatusAsync(orderId, "shipped");
        if (!success)
            return NotFound(new { error = "Ordre ikke fundet" });

        return Ok(new { message = "Ordre markeret som sendt" });
    }
}
