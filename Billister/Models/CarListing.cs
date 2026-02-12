namespace Billister.Models;

public sealed class CarListing
{
    public Guid Id { get; set; } = Guid.NewGuid();

    // Ownership
    public Guid SellerUserId { get; set; }

    // Core
    public string Make { get; set; } = string.Empty; // mærke
    public string Model { get; set; } = string.Empty;
    public string? Variant { get; set; }

    public int? Year { get; set; }
    public int? MileageKm { get; set; }
    public decimal PriceDkk { get; set; }

    public string FuelType { get; set; } = string.Empty; // el, hybrid, benzin, diesel
    public bool? IsPlugInHybrid { get; set; }
    public int? ElectricRangeKm { get; set; }
    public decimal? BatteryKwh { get; set; }

    public string Transmission { get; set; } = string.Empty; // manuel, automat
    public string? BodyType { get; set; }
    public string? Color { get; set; }

    public int? Doors { get; set; }
    public int? Seats { get; set; }

    public int? Horsepower { get; set; }
    public int? Kilowatts { get; set; }

    public decimal? EngineLiters { get; set; }
    public int? Cylinders { get; set; }

    public bool? HasTowHook { get; set; }
    public bool? HasFourWheelDrive { get; set; }

    // Location for map/nearby
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public string? PostalCode { get; set; }
    public string? City { get; set; }

    // Text
    public string? Title { get; set; }
    public string? Description { get; set; }

    // Features / equipment: stored as JSON array of strings (e.g. ["navigation","leather","adaptive_cruise"]).
    public string FeaturesJson { get; set; } = "[]";

    // Extra attributes (for 40+ params) stored as JSON object to avoid schema churn.
    public string ExtraAttributesJson { get; set; } = "{}";

    // Stats
    public long ViewCount { get; set; }
    public long FavoriteCount { get; set; }

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAtUtc { get; set; }

    public List<CarImage> Images { get; set; } = new();
}
