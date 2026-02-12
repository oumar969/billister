namespace Billister.Services;

public sealed record MotorregisterVehicleDto(
    string LicensePlate,
    string? Make,
    string? Model,
    int? Year,
    string? FuelType,
    int? Kilowatts,
    int? Horsepower);

public interface IMotorregisterService
{
    Task<MotorregisterVehicleDto?> LookupByPlateAsync(string licensePlate, CancellationToken ct);
}

// Stub: wire up to Motorregister API later.
public sealed class MotorregisterService : IMotorregisterService
{
    public Task<MotorregisterVehicleDto?> LookupByPlateAsync(string licensePlate, CancellationToken ct)
    {
        return Task.FromResult<MotorregisterVehicleDto?>(null);
    }
}
