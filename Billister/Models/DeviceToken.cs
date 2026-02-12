namespace Billister.Models;

public sealed class DeviceToken
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }

    // e.g. "android" | "ios"
    public string Platform { get; set; } = string.Empty;

    // Firebase device token
    public string Token { get; set; } = string.Empty;

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}
