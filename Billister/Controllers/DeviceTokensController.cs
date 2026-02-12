using System.Security.Claims;
using Billister.Contracts;
using Billister.Data;
using Billister.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Billister.Controllers;

[ApiController]
[Authorize]
[Route("api/device-tokens")]
public sealed class DeviceTokensController : ControllerBase
{
    private readonly BillisterDbContext _db;

    public DeviceTokensController(BillisterDbContext db)
    {
        _db = db;
    }

    [HttpPost]
    public async Task<ActionResult> Upsert([FromBody] ApiDtos.DeviceTokens.UpsertDeviceTokenRequest req, CancellationToken ct)
    {
        var userId = GetUserId();

        var existing = await _db.DeviceTokens
            .FirstOrDefaultAsync(x => x.UserId == userId && x.Platform == req.Platform, ct);

        if (existing is null)
        {
            _db.DeviceTokens.Add(new DeviceToken
            {
                UserId = userId,
                Platform = req.Platform,
                Token = req.Token
            });
        }
        else
        {
            existing.Token = req.Token;
        }

        await _db.SaveChangesAsync(ct);
        return NoContent();
    }

    private Guid GetUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.Parse(sub!);
    }
}
