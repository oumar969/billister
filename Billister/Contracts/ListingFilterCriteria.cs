using System.Text.Json;

namespace Billister.Contracts;

public sealed record ListingFilterCriteria
{
    public string? Q { get; init; }

    // Sale type
    public bool? IsLeasing { get; init; }
    public List<string>? SellerTypes { get; init; } // "private", "dealer"
    public List<string>? SaleTypes { get; init; } // "commission", "formidling"

    // Make / Model
    public List<string>? Makes { get; init; }
    public List<string>? Models { get; init; }

    // Body type
    public List<string>? BodyTypes { get; init; }

    // Fuel type & transmission
    public List<string>? FuelTypes { get; init; }
    public List<string>? Transmissions { get; init; }

    // Price
    public decimal? PriceMin { get; init; }
    public decimal? PriceMax { get; init; }

    // Year
    public int? YearMin { get; init; }
    public int? YearMax { get; init; }

    // First registration year (Ågang)
    public int? FirstRegistrationYearMin { get; init; }
    public int? FirstRegistrationYearMax { get; init; }

    // Mileage
    public int? MileageMin { get; init; }
    public int? MileageMax { get; init; }

    // Range (for EV)
    public int? RangeMin { get; init; }
    public int? RangeMax { get; init; }

    // Performance
    public int? HorsepowerMin { get; init; }
    public int? HorsepowerMax { get; init; }

    public int? KilowattsMin { get; init; }
    public int? KilowattsMax { get; init; }

    // Features
    public bool? HasTowHook { get; init; }
    public bool? HasFourWheelDrive { get; init; }

    // Require that all listed features exist on the listing.
    public List<string>? RequiredFeatures { get; init; }

    // Map / nearby: center + radius.
    public double? CenterLat { get; init; }
    public double? CenterLng { get; init; }
    public double? RadiusKm { get; init; }

    // Arbitrary extra filters. Values can be string/number/bool/array of those.
    public Dictionary<string, JsonElement>? Extra { get; init; }

    // Sorting: newest (default), price_asc, price_desc, mileage_asc, mileage_desc, year_desc, year_asc
    public string? SortBy { get; init; }
}
