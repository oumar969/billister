using Microsoft.AspNetCore.Mvc;

namespace Billister.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UrlParserController : ControllerBase
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<UrlParserController> _logger;

    public UrlParserController(ILogger<UrlParserController> logger)
    {
        _httpClient = new HttpClient { Timeout = TimeSpan.FromSeconds(10) };
        _httpClient.DefaultRequestHeaders.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
        _logger = logger;
    }

    [HttpPost("parse-listing")]
    public async Task<IActionResult> ParseListing([FromBody] ParseUrlRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Url))
        {
            return BadRequest(new { error = "URL er påkrævet" });
        }

        try
        {
            // Fetch HTML from the URL
            var response = await _httpClient.GetAsync(request.Url);
            if (!response.IsSuccessStatusCode)
            {
                return BadRequest(new { error = $"Kunne ikke hente siden (HTTP {response.StatusCode})" });
            }

            var html = await response.Content.ReadAsStringAsync();
            var data = ParseHtml(html, request.Url);

            return Ok(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error parsing URL");
            return BadRequest(new { error = $"Fejl ved parsing: {ex.Message}" });
        }
    }

    private Dictionary<string, object?> ParseHtml(string html, string url)
    {
        var data = new Dictionary<string, object?>();

        // Extract title from h1, h2, or title tag
        var titleMatch = System.Text.RegularExpressions.Regex.Match(
            html,
            @"<(?:h1|h2|title)[^>]*>([^<]+)</(?:h1|h2|title)>",
            System.Text.RegularExpressions.RegexOptions.IgnoreCase
        );
        if (titleMatch.Success)
        {
            var title = titleMatch.Groups[1].Value;
            if (!string.IsNullOrWhiteSpace(title))
            {
                title = System.Net.WebUtility.HtmlDecode(title.Trim());
                data["title"] = title;

                // Extract make and model from title
                // Expected format: "Brugt Citroën C3 1,5 BlueHDi..." or "Brugt [Make] [Model] ..."
                var titleParts = System.Text.RegularExpressions.Regex.Split(
                    title,
                    @"\s+",
                    System.Text.RegularExpressions.RegexOptions.IgnoreCase
                );

                if (titleParts.Length >= 2)
                {
                    int startIdx = titleParts[0].Equals("Brugt", System.StringComparison.OrdinalIgnoreCase) ? 1 : 0;

                    if (startIdx < titleParts.Length)
                    {
                        // First meaningful word is typically the make (brand)
                        var make = titleParts[startIdx];
                        if (!string.IsNullOrWhiteSpace(make) && make.Length > 1)
                        {
                            data["make"] = make;
                        }
                    }

                    if (startIdx + 1 < titleParts.Length)
                    {
                        // Second meaningful word is typically the model
                        var model = titleParts[startIdx + 1];
                        // Skip if it's a number or engine type
                        if (!string.IsNullOrWhiteSpace(model)
                            && model.Length > 0
                            && !System.Text.RegularExpressions.Regex.IsMatch(model, @"^\d+[,.]?\d*$")
                            && !System.Text.RegularExpressions.Regex.IsMatch(model, @"^(BlueHDi|HDi|TDi|TSi|TCe)", System.Text.RegularExpressions.RegexOptions.IgnoreCase))
                        {
                            data["model"] = model;
                        }
                    }
                }
            }
        }

        // Extract license plate (Danish format: AB12345 or variations)
        var licensePlateMatch = System.Text.RegularExpressions.Regex.Match(
            html,
            @"(?:nummerplade|license\s+plate|reg\.?\s+nr\.?|registrering)[:\s=]+([A-Z]{2}\s*\d{5}|[A-Z]{2}\d{5})",
            System.Text.RegularExpressions.RegexOptions.IgnoreCase
        );
        if (licensePlateMatch.Success)
        {
            var plate = licensePlateMatch.Groups[1].Value.Replace(" ", "").Trim();
            if (!string.IsNullOrWhiteSpace(plate))
            {
                data["licensePlate"] = plate.ToUpperInvariant();
            }
        }

        // Extract year (4 digits between 1950 and current year + 1)
        var yearMatch = System.Text.RegularExpressions.Regex.Match(html, @"\b(19|20)\d{2}\b");
        if (yearMatch.Success)
        {
            if (int.TryParse(yearMatch.Groups[0].Value, out var year))
            {
                if (year >= 1950 && year <= DateTime.Now.Year + 1)
                {
                    data["year"] = year;
                }
            }
        }

        // Extract price - Bilbasen specific patterns
        var pricePatterns = new[]
        {
            @"<span[^>]*class=[""']price[""'][^>]*>([0-9.,\s]+)", // span with price class
            @"(?:pris|price|dkk)[:\s=]+(?:[^\d])*([0-9]{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)",
            @"<strong[^>]*>([0-9]{1,3}(?:[.,]\d{3})*)[^<]*kr", // strong with kr suffix
            @"([0-9]{2,3}\.\d{3})\s*(?:kr|dkk)" // xxxxx kr format
        };

        foreach (var pattern in pricePatterns)
        {
            var priceMatch = System.Text.RegularExpressions.Regex.Match(html, pattern, System.Text.RegularExpressions.RegexOptions.IgnoreCase);
            if (priceMatch.Success)
            {
                var priceStr = priceMatch.Groups[1].Value.Replace(".", "").Replace(",", "").Trim();
                if (int.TryParse(priceStr, out var price) && price > 5000) // Min 5000 kr
                {
                    data["price"] = price;
                    break;
                }
            }
        }

        // Extract mileage/km - Bilbasen patterns - try multiple patterns
        var mileagePatterns = new[]
        {
            @"(?:km|kilometer|mil)[:\s=]+([0-9\s.,]+)(?:\s|<|[a-z])",
            @"<[^>]*>\s*([0-9\s.,]+)\s*(?:km|kilometer)\s*</[^>]*>",
            @">([0-9]{1,3}\.?[0-9]{3})\s*km<",
        };

        foreach (var pattern in mileagePatterns)
        {
            var mileageMatch = System.Text.RegularExpressions.Regex.Match(html, pattern, System.Text.RegularExpressions.RegexOptions.IgnoreCase);
            if (mileageMatch.Success)
            {
                var mileageStr = mileageMatch.Groups[1].Value.Replace(".", "").Replace(",", "").Trim();
                if (int.TryParse(mileageStr, out var mileage) && mileage >= 0)
                {
                    data["mileage"] = mileage;
                    break;
                }
            }
        }

        // Extract city - Bilbasen patterns - be more careful to avoid false positives
        var cityPatterns = new[]
        {
            // Look for city name in seller/location context
            @"(?:Sælger|Bosted|Lokation)[:\s=]+<[^>]*>([A-Z][a-zæøå\s]{2,30})<",
            @"(?:Sælger|Bosted)[:\s=]+([A-Z][a-zæøå\s]{2,30})",
            // Danish cities at end of address (before Denmark)
            @"([A-Z][a-zæøå]+(?:\s+[A-Z][a-zæøå]+)?)\s*,\s*(?:Danmark|DK)",
            // Avoid matching HTML attributes or CSS
            @">([A-Z][a-zæøå]{2,30})<\/(?:span|div|p|li)>",
        };

        foreach (var pattern in cityPatterns)
        {
            var cityMatch = System.Text.RegularExpressions.Regex.Match(html, pattern, System.Text.RegularExpressions.RegexOptions.IgnoreCase);
            if (cityMatch.Success)
            {
                var city = cityMatch.Groups[1].Value.Trim();
                // Reject common false positives and invalid values
                var lowerCity = city.ToLowerInvariant();
                if (!string.IsNullOrWhiteSpace(city)
                    && city.Length >= 2 && city.Length < 50
                    && !lowerCity.Contains("tracking")
                    && !lowerCity.Contains("script")
                    && !lowerCity.Contains("style")
                    && !lowerCity.Contains("@")
                    && !lowerCity.Contains("cvr")
                    && !lowerCity.Contains("javascript"))
                {
                    data["city"] = city;
                    break;
                }
            }
        }

        // Extract fuel type - check engine types FIRST with priority
        // Engine types like BlueHDi, HDi, TDi must be matched before generic keywords
        var fuelPatterns = new[]
        {
            // Specific engine types (highest priority)
            (@"BlueHDi|HDi(?!\w)", "diesel"),
            (@"\bTDi\b", "diesel"),
            (@"\bTCe\b", "benzin"),
            (@"\bTSi\b", "benzin"),
            // Generic fuel types
            (@"\bdiesel\b", "diesel"),
            (@"\bbenzin\b", "benzin"),
            (@"\bel\b", "el"),
            (@"\bhybrid\b", "hybrid"),
            (@"\belectric\b", "el"),
            (@"\bpetrol\b", "benzin"),
        };

        foreach (var (pattern, fuelType) in fuelPatterns)
        {
            var fuelMatch = System.Text.RegularExpressions.Regex.Match(
                html,
                pattern,
                System.Text.RegularExpressions.RegexOptions.IgnoreCase
            );
            if (fuelMatch.Success)
            {
                if (new[] { "el", "benzin", "diesel", "hybrid" }.Contains(fuelType))
                {
                    data["fuelType"] = fuelType;
                    break; // Use first match found
                }
            }
        }

        // Extract transmission
        var transmissionMatch = System.Text.RegularExpressions.Regex.Match(
            html,
            @"(automat|manuel|automatic|manual)",
            System.Text.RegularExpressions.RegexOptions.IgnoreCase
        );
        if (transmissionMatch.Success)
        {
            var trans = transmissionMatch.Groups[1].Value.ToLowerInvariant();
            // Normalize transmission
            trans = trans switch
            {
                "automatic" => "automat",
                "manual" => "manuel",
                _ => trans
            };
            if (new[] { "automat", "manuel" }.Contains(trans))
            {
                data["transmission"] = trans;
            }
        }

        // Extract description from meta description, og/article description, or content sections
        // Avoid CVR numbers and other metadata
        var metaDescMatch = System.Text.RegularExpressions.Regex.Match(
            html,
            @"<meta\s+(?:property=[""']og:description[""']|name=[""']description[""'])\s+content=[""']([^""']+)[""']",
            System.Text.RegularExpressions.RegexOptions.IgnoreCase
        );
        if (metaDescMatch.Success)
        {
            var desc = System.Net.WebUtility.HtmlDecode(metaDescMatch.Groups[1].Value).Trim();
            if (!string.IsNullOrWhiteSpace(desc) && desc.Length > 20 && !desc.ToLowerInvariant().StartsWith("cvr"))
            {
                data["description"] = desc.Substring(0, Math.Min(500, desc.Length));
            }
        }

        // Fall back to article description or main content paragraph
        if (!data.ContainsKey("description"))
        {
            var contentMatch = System.Text.RegularExpressions.Regex.Match(
                html,
                @"<(?:article|div[^>]*class=[""']content[""'][^>]*)[^>]*>.*?<p[^>]*>([^<]{50,}?)</p>",
                System.Text.RegularExpressions.RegexOptions.IgnoreCase | System.Text.RegularExpressions.RegexOptions.Singleline
            );
            if (contentMatch.Success)
            {
                var desc = System.Net.WebUtility.HtmlDecode(contentMatch.Groups[1].Value).Trim();
                if (!string.IsNullOrWhiteSpace(desc) && !desc.ToLowerInvariant().StartsWith("cvr"))
                {
                    data["description"] = desc.Substring(0, Math.Min(500, desc.Length));
                }
            }
            else
            {
                // Last resort: first substantial paragraph
                var pMatch = System.Text.RegularExpressions.Regex.Match(
                    html,
                    @"<p[^>]*>([^<]{30,}?)</p>",
                    System.Text.RegularExpressions.RegexOptions.IgnoreCase
                );
                if (pMatch.Success)
                {
                    var desc = System.Net.WebUtility.HtmlDecode(pMatch.Groups[1].Value).Trim();
                    if (!string.IsNullOrWhiteSpace(desc) && !desc.ToLowerInvariant().Contains("cvr"))
                    {
                        data["description"] = desc.Substring(0, Math.Min(500, desc.Length));
                    }
                }
            }
        }

        return data;
    }
}

public class ParseUrlRequest
{
    public string Url { get; set; } = string.Empty;
}
