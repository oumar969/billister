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
        var result = await _motor.LookupByPlateAsync(licensePlate, ct);
        if (result is null) return NotFound();
        return Ok(result);
    }
}
