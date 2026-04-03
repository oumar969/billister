using System;

namespace Billister.Models
{
    /// <summary>
    /// Cache for license plate lookups to avoid repeated scraping
    /// </summary>
    /// https://pypi.org/project/dmr.py/
    public class LicensePlateLookupCache
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();

        /// <summary>Danish license plate (e.g., "AB12345")</summary>
        public string LicensePlate { get; set; } = string.Empty;

        /// <summary>Vehicle make/manufacturer (e.g., "Toyota")</summary>
        public string Make { get; set; } = string.Empty;

        /// <summary>Vehicle model (e.g., "Yaris")</summary>
        public string Model { get; set; } = string.Empty;

        /// <summary>Vehicle year/first registration year</summary>
        public int? Year { get; set; }

        /// <summary>Fuel type (e.g., "Benzin", "Diesel", "El")</summary>
        public string? FuelType { get; set; }

        /// <summary>Transmission type (e.g., "Manuel", "Automat")</summary>
        public string? Transmission { get; set; }

        /// <summary>Mileage in kilometers</summary>
        public int? Kilometers { get; set; }

        /// <summary>Engine size/displacement</summary>
        public string? EngineSize { get; set; }

        /// <summary>Vehicle color</summary>
        public string? Color { get; set; }

        /// <summary>CO2 emissions in g/km</summary>
        public int? Co2Emissions { get; set; }

        /// <summary>Euro standard (e.g., "Euro 6b")</summary>
        public string? EuroStandard { get; set; }

        /// <summary>Full vehicle data as JSON (in case we need other fields later)</summary>
        public string? RawJsonData { get; set; }

        /// <summary>When this cache entry was created</summary>
        public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

        /// <summary>When this cache entry was last used/accessed</summary>
        public DateTime LastAccessedAtUtc { get; set; } = DateTime.UtcNow;

        /// <summary>Number of times this cache entry has been accessed</summary>
        public int AccessCount { get; set; } = 0;

        /// <summary>Error message if lookup failed (null if successful)</summary>
        public string? ErrorMessage { get; set; }

        /// <summary>Was the lookup successful?</summary>
        public bool IsSuccessful => string.IsNullOrEmpty(ErrorMessage) && !string.IsNullOrEmpty(Make);
    }
}
