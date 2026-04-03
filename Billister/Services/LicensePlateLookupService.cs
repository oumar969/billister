using System.Net.Http;
using System.Threading.Tasks;
using Billister.Models;
using Billister.Data;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Text.Json;

namespace Billister.Services;

/// <summary>
/// Service for looking up Danish vehicle information from license plates
/// Calls a Python Flask server (http://localhost:8000) that scrapes motorregister.skat.dk
/// Caches results in the database for 30 days
/// </summary>
public class LicensePlateLookupService
{
    private readonly HttpClient _httpClient;
    private readonly BillisterDbContext _dbContext;
    private readonly ILogger<LicensePlateLookupService> _logger;

    private const string FLASK_SERVER_URL = "http://localhost:8000/api/vehicles/plate";
    private const int CACHE_DURATION_DAYS = 30;

    public LicensePlateLookupService(
        HttpClient httpClient,
        BillisterDbContext dbContext,
        ILogger<LicensePlateLookupService> logger)
    {
        _httpClient = httpClient;
        _dbContext = dbContext;
        _logger = logger;
    }

    /// <summary>
    /// Lookup vehicle by Danish license plate
    /// First checks cache, then calls Flask server if not cached
    /// </summary>
    public async Task<LicensePlateLookupCache?> LookupByPlateAsync(string licensePlate)
    {
        if (string.IsNullOrWhiteSpace(licensePlate))
        {
            _logger.LogWarning("License plate lookup requested with empty plate");
            return null;
        }

        licensePlate = licensePlate.Trim().ToUpper();

        // Validate plate format (Danish format: AB12345 or AB 12345)
        if (!ValidateLicensePlateFormat(licensePlate))
        {
            _logger.LogWarning($"Invalid license plate format: {licensePlate}");
            return null;
        }

        try
        {
            // Check cache first
            var cached = await _dbContext.LicensePlateLookupCaches
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.LicensePlate == licensePlate);

            if (cached != null)
            {
                _logger.LogInformation($"✅ Cache hit for plate: {licensePlate}");

                // Update access info asynchronously
                _ = _dbContext.LicensePlateLookupCaches
                    .Where(x => x.Id == cached.Id)
                    .ExecuteUpdateAsync(x => x
                        .SetProperty(p => p.LastAccessedAtUtc, DateTime.UtcNow)
                        .SetProperty(p => p.AccessCount, p => p.AccessCount + 1));

                return cached;
            }

            // Cache miss - call Flask server
            _logger.LogInformation($"📋 Cache miss, calling Flask server for plate: {licensePlate}");
            var result = await LookupFromFlaskAsync(licensePlate);

            if (result != null)
            {
                // Save to cache
                _dbContext.LicensePlateLookupCaches.Add(result);
                await _dbContext.SaveChangesAsync();
                _logger.LogInformation($"💾 Saved lookup result to cache for plate: {licensePlate}");
            }

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError($"💥 Error looking up license plate {licensePlate}: {ex.Message}");
            return null;
        }
    }

    /// <summary>
    /// Call Flask server to lookup vehicle data from motorregister
    /// </summary>
    private async Task<LicensePlateLookupCache?> LookupFromFlaskAsync(string licensePlate)
    {
        var cleanPlate = licensePlate.Replace(" ", "").ToUpper();

        try
        {
            _logger.LogInformation($"🔍 Calling Flask server for plate: {licensePlate} at {FLASK_SERVER_URL}");

            var requestUri = $"{FLASK_SERVER_URL}/{Uri.EscapeDataString(cleanPlate)}";
            var response = await _httpClient.GetAsync(requestUri);

            if (!response.IsSuccessStatusCode)
            {
                if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    _logger.LogWarning($"❌ Vehicle not found in flask server for plate: {licensePlate}");
                    return null;
                }

                _logger.LogWarning($"❌ Flask server returned {response.StatusCode}");
                return null;
            }

            var jsonContent = await response.Content.ReadAsStringAsync();
            _logger.LogInformation($"✅ Got JSON response from Flask: {jsonContent.Substring(0, Math.Min(200, jsonContent.Length))}");

            // Parse JSON response
            using (var jsonDoc = JsonDocument.Parse(jsonContent))
            {
                var root = jsonDoc.RootElement;

                if (!root.TryGetProperty("success", out var successEl) || !successEl.GetBoolean())
                {
                    _logger.LogWarning($"⚠️  Flask returned success=false for plate: {licensePlate}");
                    return null;
                }

                if (!root.TryGetProperty("data", out var dataEl))
                {
                    _logger.LogWarning($"⚠️  Flask response missing 'data' field");
                    return null;
                }

                var data = dataEl;

                var result = new LicensePlateLookupCache
                {
                    LicensePlate = licensePlate,
                    Make = GetStringProperty(data, "make"),
                    Model = GetStringProperty(data, "model"),
                    Year = GetIntProperty(data, "year"),
                    FuelType = GetStringProperty(data, "fuelType"),
                    Transmission = GetStringProperty(data, "transmission"),
                    Kilometers = GetIntProperty(data, "kilometers"),
                    Color = GetStringProperty(data, "color"),
                    Co2Emissions = GetIntProperty(data, "co2Emissions"),
                    CreatedAtUtc = DateTime.UtcNow,
                    LastAccessedAtUtc = DateTime.UtcNow,
                    AccessCount = 1
                };

                _logger.LogInformation($"✓ Parsed vehicle from Flask: {result.Make} {result.Model} ({result.Year})");
                return result;
            }
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError($"💥 HTTP error calling Flask server: {ex.Message}");
            return null;
        }
        catch (JsonException ex)
        {
            _logger.LogError($"💥 JSON parsing error from Flask response: {ex.Message}");
            return null;
        }
        catch (Exception ex)
        {
            _logger.LogError($"💥 Error calling Flask server for {licensePlate}: {ex.Message}");
            return null;
        }
    }

    /// <summary>
    /// Helper to extract string property from JSON
    /// </summary>
    private string? GetStringProperty(JsonElement element, string propertyName)
    {
        if (element.TryGetProperty(propertyName, out var prop) && prop.ValueKind == JsonValueKind.String)
        {
            return prop.GetString();
        }
        return null;
    }

    /// <summary>
    /// Helper to extract int property from JSON
    /// </summary>
    private int? GetIntProperty(JsonElement element, string propertyName)
    {
        if (element.TryGetProperty(propertyName, out var prop) && prop.ValueKind == JsonValueKind.Number)
        {
            if (prop.TryGetInt32(out var intValue))
            {
                return intValue;
            }
        }
        return null;
    }

    /// <summary>
    /// Validate Danish license plate format
    /// </summary>
    private bool ValidateLicensePlateFormat(string plate)
    {
        if (string.IsNullOrEmpty(plate))
            return false;

        var cleanPlate = plate.Replace(" ", "").ToUpper();

        // Danish plates: 2 letters + 5 digits, or old format variations
        return cleanPlate.Length >= 6 && cleanPlate.Length <= 7 &&
               cleanPlate.All(c => char.IsLetterOrDigit(c));
    }

    /// <summary>
    /// Clear old cache entries (older than CACHE_DURATION_DAYS)
    /// </summary>
    public async Task<int> ClearOldCacheAsync()
    {
        var cutoffDate = DateTime.UtcNow.AddDays(-CACHE_DURATION_DAYS);
        var deleted = await _dbContext.LicensePlateLookupCaches
            .Where(x => x.CreatedAtUtc < cutoffDate)
            .ExecuteDeleteAsync();

        _logger.LogInformation($"Cleared {deleted} old cache entries");
        return deleted;
    }

    /// <summary>
    /// Get cache statistics
    /// </summary>
    public async Task<(int totalEntries, int successfulLookups, int failedLookups, int totalAccess)> GetCacheStatsAsync()
    {
        var stats = await _dbContext.LicensePlateLookupCaches
            .AsNoTracking()
            .GroupBy(x => true)
            .Select(g => new
            {
                Total = g.Count(),
                Successful = g.Count(x => x.Make != string.Empty),
                Failed = g.Count(x => x.Make == string.Empty),
                TotalAccess = g.Sum(x => x.AccessCount)
            })
            .FirstOrDefaultAsync();

        return (
            stats?.Total ?? 0,
            stats?.Successful ?? 0,
            stats?.Failed ?? 0,
            stats?.TotalAccess ?? 0
        );
    }
}
