using Billister.Services;
using Microsoft.AspNetCore.Mvc;

namespace Billister.Controllers;

[ApiController]
[Route("api/vehicles")]
public sealed class VehiclesController : ControllerBase
{
    private readonly IMotorregisterService _motor;

    public VehiclesController(IMotorregisterService motor)
    {
        _motor = motor;
    }

    [HttpGet("plate/{licensePlate}")]
    public async Task<ActionResult<object>> LookupPlate([FromRoute] string licensePlate, CancellationToken ct)
    {
        var result = await _motor.LookupByPlateAsync(licensePlate, ct);
        if (result is null) return NotFound();
        return Ok(result);
    }
}
