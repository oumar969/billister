namespace Billister.Contracts;

public static class ApiDtos
{
    public static class Auth
    {
        public sealed record RegisterRequest(string Email, string Password);
        public sealed record LoginRequest(string Email, string Password);
        public sealed record AuthResponse(string Token);
    }

    public static class Listings
    {
        public sealed record ListingImageDto(string Url, int SortOrder, int? Width, int? Height);

        public sealed record CreateListingRequest(
            string Make,
            string Model,
            decimal PriceDkk,
            string FuelType,
            string Transmission,
            string? Variant,
            int? Year,
            int? MileageKm,
            int? ElectricRangeKm,
            decimal? BatteryKwh,
            bool? IsPlugInHybrid,
            string? BodyType,
            string? Color,
            int? Doors,
            int? Seats,
            int? Horsepower,
            int? Kilowatts,
            decimal? EngineLiters,
            int? Cylinders,
            bool? HasTowHook,
            bool? HasFourWheelDrive,
            double? Latitude,
            double? Longitude,
            string? PostalCode,
            string? City,
            string? Title,
            string? Description,
            List<string>? Features,
            Dictionary<string, object?>? ExtraAttributes,
            List<ListingImageDto>? Images);

        public sealed record UpdateListingRequest(
            decimal? PriceDkk,
            int? MileageKm,
            string? Title,
            string? Description,
            List<string>? Features,
            Dictionary<string, object?>? ExtraAttributes,
            List<ListingImageDto>? Images);

        // GET /api/listings query params (simple filters)
        public sealed record ListingQuery(
            string? Q,
            string? Make,
            string? Model,
            string? FuelType,
            string? Transmission,
            decimal? PriceMin,
            decimal? PriceMax,
            int? YearMin,
            int? YearMax,
            int? MileageMin,
            int? MileageMax,
            int? RangeMin,
            int? RangeMax,
            bool? HasTowHook,
            bool? HasFourWheelDrive,
            string? Feature,
            int Page = 1,
            int PageSize = 20);

        // POST /api/listings/search (advanced filters for 40+ params)
        public sealed record ListingsSearchRequest(ListingFilterCriteria Criteria, int Page = 1, int PageSize = 20);
    }

    public static class SavedSearches
    {
        public sealed record CreateSavedSearchRequest(string Name, string CriteriaJson);
        public sealed record UpdateSavedSearchRequest(string? Name, string? CriteriaJson);

        public sealed record CreateSavedSearchFromCriteriaRequest(string Name, ListingFilterCriteria Criteria);
    }

    public static class DeviceTokens
    {
        public sealed record UpsertDeviceTokenRequest(string Platform, string Token);
    }

    public static class Chats
    {
        public sealed record StartChatRequest(Guid ListingId);
    }
}
