using Billister.Data;
using Billister.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Mvc;

namespace Billister.Controllers;

[ApiController]
[Route("api/vehicles")]
public sealed class VehiclesController : ControllerBase
{
    private readonly IMotorregisterService _motor;
    private readonly BillisterDbContext _db;

    public VehiclesController(IMotorregisterService motor, BillisterDbContext db)
    {
        _motor = motor;
        _db = db;
    }

    [HttpGet("makes")]
    public async Task<ActionResult<object>> GetMakes(CancellationToken ct)
    {
        var makes = await _db.VehicleMakes
            .AsNoTracking()
            .OrderBy(x => x.Name)
            .Select(x => new { x.Id, x.Name })
            .ToListAsync(ct);

        return Ok(makes);
    }

    [HttpGet("makes/{makeId:guid}/models")]
    public async Task<ActionResult<object>> GetModelsByMake([FromRoute] Guid makeId, CancellationToken ct)
    {
        var models = await _db.VehicleModels
            .AsNoTracking()
            .Where(x => x.MakeId == makeId)
            .OrderBy(x => x.Name)
            .Select(x => new { x.Id, x.MakeId, x.Name })
            .ToListAsync(ct);

        return Ok(models);
    }

    [HttpGet("plate/{licensePlate}")]
    public async Task<ActionResult<object>> LookupPlate([FromRoute] string licensePlate, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(licensePlate))
        {
            return BadRequest(new { error = "License plate is required" });
        }

        try
        {
            var vehicle = await _motor.LookupByPlateAsync(licensePlate, ct);

            if (vehicle == null)
            {
                return NotFound(new
                {
                    error = "Køretøj ikke fundet",
                    message = $"No vehicle found for plate: {licensePlate}"
                });
            }

            return Ok(new
            {
                success = true,
                data = vehicle
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new
            {
                error = "Server error",
                message = ex.Message
            });
        }
    }

    [HttpGet("debug/plate/{licensePlate}")]
    public async Task<ActionResult<object>> DebugLookupPlate([FromRoute] string licensePlate, CancellationToken ct)
    {
        // For debugging motorregister scraping
        return Ok(new
        {
            plate = licensePlate,
            message = "Use /api/vehicles/plate/{plate} for actual lookup",
            hint = "Check backend logs for scraping details"
        });
    }
}
