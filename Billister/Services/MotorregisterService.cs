namespace Billister.Services;

public sealed record MotorregisterVehicleDto(
    string LicensePlate,
    string? Make,
    string? Model,
    int? Year,
    string? FuelType,
    string? Transmission,
    int? Kilometers,
    string? Color,
    int? Co2Emissions,
    int? Kilowatts = null,
    int? Horsepower = null);

public interface IMotorregisterService
{
    Task<MotorregisterVehicleDto?> LookupByPlateAsync(string licensePlate, CancellationToken ct);
}

/// <summary>
/// Implementation that uses LicensePlateLookupService to scrape motorregister.skat.dk
/// with caching in the database
/// </summary>
public sealed class MotorregisterService : IMotorregisterService
{
    private readonly LicensePlateLookupService _licensePlateLookupService;
    private readonly ILogger<MotorregisterService> _logger;

    public MotorregisterService(
        LicensePlateLookupService licensePlateLookupService,
        ILogger<MotorregisterService> logger)
    {
        _licensePlateLookupService = licensePlateLookupService;
        _logger = logger;
    }

    public async Task<MotorregisterVehicleDto?> LookupByPlateAsync(string licensePlate, CancellationToken ct)
    {
        try
        {
            var cached = await _licensePlateLookupService.LookupByPlateAsync(licensePlate);

            if (cached == null || !cached.IsSuccessful)
            {
                _logger.LogWarning($"Lookup failed for plate: {licensePlate}");
                return null;
            }

            return new MotorregisterVehicleDto(
                LicensePlate: cached.LicensePlate,
                Make: cached.Make,
                Model: cached.Model,
                Year: cached.Year,
                FuelType: cached.FuelType,
                Transmission: cached.Transmission,
                Kilometers: cached.Kilometers,
                Color: cached.Color,
                Co2Emissions: cached.Co2Emissions
            );
        }
        catch (Exception ex)
        {
            _logger.LogError($"Error in MotorregisterService.LookupByPlateAsync: {ex.Message}");
            return null;
        }
    }
}
