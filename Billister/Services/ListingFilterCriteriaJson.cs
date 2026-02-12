using System.Text.Json;
using Billister.Contracts;

namespace Billister.Services;

public static class ListingFilterCriteriaJson
{
    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        WriteIndented = false
    };

    public static bool TryParse(string json, out ListingFilterCriteria criteria, out string normalizedJson)
    {
        criteria = new ListingFilterCriteria();
        normalizedJson = "{}";

        if (string.IsNullOrWhiteSpace(json))
        {
            return false;
        }

        try
        {
            criteria = JsonSerializer.Deserialize<ListingFilterCriteria>(json, SerializerOptions) ?? new ListingFilterCriteria();
            normalizedJson = JsonSerializer.Serialize(criteria, SerializerOptions);
            return true;
        }
        catch
        {
            return false;
        }
    }

    public static ListingFilterCriteria ParseOrEmpty(string json)
    {
        if (TryParse(json, out var criteria, out _))
        {
            return criteria;
        }

        return new ListingFilterCriteria();
    }

    public static string Normalize(string json)
    {
        if (TryParse(json, out _, out var normalized))
        {
            return normalized;
        }

        throw new InvalidOperationException("Invalid CriteriaJson");
    }

    public static string Normalize(ListingFilterCriteria criteria)
    {
        return JsonSerializer.Serialize(criteria ?? new ListingFilterCriteria(), SerializerOptions);
    }
}
