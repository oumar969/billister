using System.Text.Json;
using Billister.Contracts;
using Billister.Models;

namespace Billister.Services;

public static class ListingCriteriaMatcher
{
    public static bool IsMatch(CarListing listing, ListingFilterCriteria criteria)
    {
        if (!IsNullOrContainsText(listing, criteria.Q)) return false;

        if (criteria.Makes is { Count: > 0 } && !ContainsIgnoreCase(criteria.Makes, listing.Make)) return false;
        if (criteria.Models is { Count: > 0 } && !ContainsIgnoreCase(criteria.Models, listing.Model)) return false;

        if (criteria.FuelTypes is { Count: > 0 } && !ContainsIgnoreCase(criteria.FuelTypes, listing.FuelType)) return false;
        if (criteria.Transmissions is { Count: > 0 } && !ContainsIgnoreCase(criteria.Transmissions, listing.Transmission)) return false;

        if (criteria.PriceMin is not null && listing.PriceDkk < criteria.PriceMin.Value) return false;
        if (criteria.PriceMax is not null && listing.PriceDkk > criteria.PriceMax.Value) return false;

        if (criteria.YearMin is not null && (listing.Year is null || listing.Year.Value < criteria.YearMin.Value)) return false;
        if (criteria.YearMax is not null && (listing.Year is null || listing.Year.Value > criteria.YearMax.Value)) return false;

        if (criteria.MileageMin is not null && (listing.MileageKm is null || listing.MileageKm.Value < criteria.MileageMin.Value)) return false;
        if (criteria.MileageMax is not null && (listing.MileageKm is null || listing.MileageKm.Value > criteria.MileageMax.Value)) return false;

        if (criteria.RangeMin is not null && (listing.ElectricRangeKm is null || listing.ElectricRangeKm.Value < criteria.RangeMin.Value)) return false;
        if (criteria.RangeMax is not null && (listing.ElectricRangeKm is null || listing.ElectricRangeKm.Value > criteria.RangeMax.Value)) return false;

        if (criteria.HorsepowerMin is not null && (listing.Horsepower is null || listing.Horsepower.Value < criteria.HorsepowerMin.Value)) return false;
        if (criteria.HorsepowerMax is not null && (listing.Horsepower is null || listing.Horsepower.Value > criteria.HorsepowerMax.Value)) return false;

        if (criteria.KilowattsMin is not null && (listing.Kilowatts is null || listing.Kilowatts.Value < criteria.KilowattsMin.Value)) return false;
        if (criteria.KilowattsMax is not null && (listing.Kilowatts is null || listing.Kilowatts.Value > criteria.KilowattsMax.Value)) return false;

        if (criteria.HasTowHook is not null && listing.HasTowHook != criteria.HasTowHook) return false;
        if (criteria.HasFourWheelDrive is not null && listing.HasFourWheelDrive != criteria.HasFourWheelDrive) return false;

        if (criteria.RequiredFeatures is { Count: > 0 })
        {
            var features = ParseStringListOrEmpty(listing.FeaturesJson);
            foreach (var required in criteria.RequiredFeatures)
            {
                if (!ContainsIgnoreCase(features, required)) return false;
            }
        }

        if (criteria.CenterLat is not null && criteria.CenterLng is not null && criteria.RadiusKm is not null)
        {
            if (listing.Latitude is null || listing.Longitude is null) return false;

            var distance = HaversineKm(criteria.CenterLat.Value, criteria.CenterLng.Value, listing.Latitude.Value, listing.Longitude.Value);
            if (distance > criteria.RadiusKm.Value) return false;
        }

        if (criteria.Extra is { Count: > 0 })
        {
            var extras = ParseJsonObjectOrEmpty(listing.ExtraAttributesJson);
            foreach (var (key, expected) in criteria.Extra)
            {
                if (!extras.TryGetValue(key, out var actual)) return false;
                if (!JsonValueMatches(actual, expected)) return false;
            }
        }

        return true;
    }

    private static bool IsNullOrContainsText(CarListing listing, string? q)
    {
        if (string.IsNullOrWhiteSpace(q)) return true;
        var needle = q.Trim();

        return ContainsIgnoreCase(listing.Make, needle)
            || ContainsIgnoreCase(listing.Model, needle)
            || ContainsIgnoreCase(listing.Variant ?? string.Empty, needle)
            || ContainsIgnoreCase(listing.Title ?? string.Empty, needle)
            || ContainsIgnoreCase(listing.Description ?? string.Empty, needle);
    }

    private static bool ContainsIgnoreCase(string haystack, string needle)
        => haystack?.IndexOf(needle, StringComparison.OrdinalIgnoreCase) >= 0;

    private static bool ContainsIgnoreCase(List<string> list, string value)
        => list.Any(x => string.Equals(x, value, StringComparison.OrdinalIgnoreCase));

    private static List<string> ParseStringListOrEmpty(string json)
    {
        try
        {
            return JsonSerializer.Deserialize<List<string>>(json) ?? new List<string>();
        }
        catch
        {
            return new List<string>();
        }
    }

    private static Dictionary<string, JsonElement> ParseJsonObjectOrEmpty(string json)
    {
        try
        {
            return JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(json) ?? new Dictionary<string, JsonElement>();
        }
        catch
        {
            return new Dictionary<string, JsonElement>();
        }
    }

    private static bool JsonValueMatches(JsonElement actual, JsonElement expected)
    {
        // Support "expected" being an array of allowed values.
        if (expected.ValueKind == JsonValueKind.Array)
        {
            foreach (var allowed in expected.EnumerateArray())
            {
                if (JsonValueMatches(actual, allowed)) return true;
            }
            return false;
        }

        if (actual.ValueKind == JsonValueKind.String && expected.ValueKind == JsonValueKind.String)
        {
            return string.Equals(actual.GetString(), expected.GetString(), StringComparison.OrdinalIgnoreCase);
        }

        if (actual.ValueKind is JsonValueKind.Number && expected.ValueKind is JsonValueKind.Number)
        {
            if (actual.TryGetDecimal(out var a) && expected.TryGetDecimal(out var e))
            {
                return a == e;
            }
        }

        if (actual.ValueKind is JsonValueKind.True or JsonValueKind.False && expected.ValueKind is JsonValueKind.True or JsonValueKind.False)
        {
            return actual.GetBoolean() == expected.GetBoolean();
        }

        // Fallback: compare raw JSON.
        return string.Equals(actual.GetRawText(), expected.GetRawText(), StringComparison.Ordinal);
    }

    private static double HaversineKm(double lat1, double lon1, double lat2, double lon2)
    {
        const double r = 6371.0;
        var dLat = DegreesToRadians(lat2 - lat1);
        var dLon = DegreesToRadians(lon2 - lon1);
        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2)
                + Math.Cos(DegreesToRadians(lat1)) * Math.Cos(DegreesToRadians(lat2))
                * Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        return r * c;
    }

    private static double DegreesToRadians(double deg) => deg * (Math.PI / 180.0);
}
