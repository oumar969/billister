using System.Text.Json;

namespace Billister.Contracts;

public sealed record ListingFilterCriteria
{
    public string? Q { get; init; }

    public List<string>? Makes { get; init; }
    public List<string>? Models { get; init; }

    public List<string>? FuelTypes { get; init; }
    public List<string>? Transmissions { get; init; }

    public decimal? PriceMin { get; init; }
    public decimal? PriceMax { get; init; }

    public int? YearMin { get; init; }
    public int? YearMax { get; init; }

    public int? MileageMin { get; init; }
    public int? MileageMax { get; init; }

    public int? RangeMin { get; init; }
    public int? RangeMax { get; init; }

    public int? HorsepowerMin { get; init; }
    public int? HorsepowerMax { get; init; }

    public int? KilowattsMin { get; init; }
    public int? KilowattsMax { get; init; }

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
}
