using Billister.Data;
using Billister.Models;
using Microsoft.EntityFrameworkCore;
using Billister.Services;

namespace Billister.Services;

public interface ISavedSearchNotifier
{
    Task OnNewListingAsync(CarListing listing, CancellationToken ct);
}

// Minimal stub: stores a notification record; actual push via Firebase can be added later.
public sealed class SavedSearchNotifier : ISavedSearchNotifier
{
    private readonly BillisterDbContext _db;

    public SavedSearchNotifier(BillisterDbContext db)
    {
        _db = db;
    }

    public async Task OnNewListingAsync(CarListing listing, CancellationToken ct)
    {
        var savedSearches = await _db.SavedSearches
            .AsNoTracking()
            .OrderByDescending(s => s.CreatedAtUtc)
            .Take(2000)
            .ToListAsync(ct);

        if (savedSearches.Count == 0)
        {
            return;
        }

        var any = false;
        foreach (var saved in savedSearches)
        {
            if (!ListingFilterCriteriaJson.TryParse(saved.CriteriaJson, out var criteria, out _))
            {
                continue;
            }

            if (!ListingCriteriaMatcher.IsMatch(listing, criteria))
            {
                continue;
            }

            _db.SearchMatchNotifications.Add(new SearchMatchNotification
            {
                UserId = saved.UserId,
                SavedSearchId = saved.Id,
                ListingId = listing.Id,
                Title = "Ny bil matcher din søgning",
                Body = $"{listing.Make} {listing.Model} er netop blevet oprettet."
            });
            any = true;
        }

        if (any)
        {
            await _db.SaveChangesAsync(ct);
        }
    }
}
