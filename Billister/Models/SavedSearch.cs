namespace Billister.Models;

public sealed class SavedSearch
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid UserId { get; set; }

    public string Name { get; set; } = string.Empty;

    // Arbitrary JSON criteria (mirrors mobile filter model)
    public string CriteriaJson { get; set; } = "{}";

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAtUtc { get; set; }

    public DateTime? LastNotifiedAtUtc { get; set; }
}
