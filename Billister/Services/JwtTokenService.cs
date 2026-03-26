using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Billister.Data;
using Billister.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

namespace Billister.Services;

public interface IJwtTokenService
{
    /// <summary>Creates a short-lived JWT access token (15 minutes).</summary>
    string CreateAccessToken(ApplicationUser user);

    /// <summary>Creates a refresh token, persists it, and returns it.</summary>
    Task<RefreshToken> CreateRefreshTokenAsync(ApplicationUser user, CancellationToken ct = default);

    /// <summary>Validates a raw refresh token string. Returns the entity when valid, null otherwise.</summary>
    Task<RefreshToken?> ValidateRefreshTokenAsync(string rawToken, CancellationToken ct = default);

    /// <summary>Revokes a single refresh token.</summary>
    Task RevokeRefreshTokenAsync(string rawToken, CancellationToken ct = default);

    /// <summary>Revokes all active refresh tokens for a user (logout everywhere).</summary>
    Task RevokeAllRefreshTokensAsync(Guid userId, CancellationToken ct = default);
}

public sealed class JwtTokenService : IJwtTokenService
{
    private static readonly TimeSpan AccessTokenLifetime = TimeSpan.FromMinutes(15);
    private static readonly TimeSpan RefreshTokenLifetime = TimeSpan.FromDays(90);

    private readonly IConfiguration _configuration;
    private readonly BillisterDbContext _db;

    public JwtTokenService(IConfiguration configuration, BillisterDbContext db)
    {
        _configuration = configuration;
        _db = db;
    }

    public string CreateAccessToken(ApplicationUser user)
    {
        var jwtSection = _configuration.GetSection("Jwt");
        var issuer = jwtSection["Issuer"] ?? "Billister";
        var audience = jwtSection["Audience"] ?? "Billister.Mobile";
        var key = jwtSection["Key"] ?? "DEV_ONLY_CHANGE_ME_please_use_user_secrets_or_env";

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
            new(ClaimTypes.NameIdentifier, user.Id.ToString())
        };

        var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key));
        var creds = new SigningCredentials(signingKey, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: DateTime.UtcNow.Add(AccessTokenLifetime),
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public async Task<RefreshToken> CreateRefreshTokenAsync(ApplicationUser user, CancellationToken ct = default)
    {
        var rawToken = GenerateSecureToken();
        var entity = new RefreshToken
        {
            UserId = user.Id,
            Token = rawToken,
            ExpiresAtUtc = DateTime.UtcNow.Add(RefreshTokenLifetime),
            CreatedAtUtc = DateTime.UtcNow
        };

        _db.RefreshTokens.Add(entity);
        await _db.SaveChangesAsync(ct);

        return entity;
    }

    public async Task<RefreshToken?> ValidateRefreshTokenAsync(string rawToken, CancellationToken ct = default)
    {
        var entity = await _db.RefreshTokens
            .FirstOrDefaultAsync(t => t.Token == rawToken, ct);

        return entity?.IsActive == true ? entity : null;
    }

    public async Task RevokeRefreshTokenAsync(string rawToken, CancellationToken ct = default)
    {
        var entity = await _db.RefreshTokens
            .FirstOrDefaultAsync(t => t.Token == rawToken, ct);

        if (entity is not null && !entity.IsRevoked)
        {
            entity.RevokedAtUtc = DateTime.UtcNow;
            await _db.SaveChangesAsync(ct);
        }
    }

    public async Task RevokeAllRefreshTokensAsync(Guid userId, CancellationToken ct = default)
    {
        var tokens = await _db.RefreshTokens
            .Where(t => t.UserId == userId && t.RevokedAtUtc == null)
            .ToListAsync(ct);

        var now = DateTime.UtcNow;
        foreach (var t in tokens)
        {
            t.RevokedAtUtc = now;
        }

        await _db.SaveChangesAsync(ct);
    }

    private static string GenerateSecureToken()
    {
        var bytes = new byte[64];
        RandomNumberGenerator.Fill(bytes);
        return Convert.ToBase64String(bytes);
    }
}
