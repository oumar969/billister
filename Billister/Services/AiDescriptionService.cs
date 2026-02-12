using Billister.Models;

namespace Billister.Services;

public interface IAiDescriptionService
{
    Task<string> GenerateDescriptionAsync(CarListing listing, CancellationToken ct);
}

// Stub service: replace with real LLM integration later.
public sealed class AiDescriptionService : IAiDescriptionService
{
    public Task<string> GenerateDescriptionAsync(CarListing listing, CancellationToken ct)
    {
        var headline = string.IsNullOrWhiteSpace(listing.Title)
            ? $"{listing.Make} {listing.Model}" + (string.IsNullOrWhiteSpace(listing.Variant) ? "" : $" {listing.Variant}")
            : listing.Title;

        var fuel = string.IsNullOrWhiteSpace(listing.FuelType) ? "" : $"{listing.FuelType}";
        var year = listing.Year is null ? "" : $"Årgang {listing.Year}. ";
        var km = listing.MileageKm is null ? "" : $"{listing.MileageKm:N0} km. ";

        var range = listing.ElectricRangeKm is null ? "" : $"Rækkevidde op til {listing.ElectricRangeKm} km. ";
        var gear = string.IsNullOrWhiteSpace(listing.Transmission) ? "" : $"Gear: {listing.Transmission}. ";

        var text = $"{headline}. {year}{km}{fuel}. {range}{gear}Velholdt bil med mulighed for fremvisning efter aftale.".Replace("  ", " ").Trim();

        return Task.FromResult(text);
    }
}
