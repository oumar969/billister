using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Billister.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace Billister.Services;

public interface IJwtTokenService
{
    string CreateAccessToken(ApplicationUser user, IList<string> roles);
    string CreateRefreshToken(ApplicationUser user, IList<string> roles);
    (bool isValid, string? userId, string? email, string? username, IList<string>? roles) ValidateRefreshToken(string token);
}

public sealed class JwtTokenService : IJwtTokenService
{
    private readonly IConfiguration _configuration;

    public JwtTokenService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    private (string issuer, string audience, string key) GetJwtConfig()
    {
        var jwtSection = _configuration.GetSection("Jwt");
        var issuer = jwtSection["Issuer"] ?? "Billister";
        var audience = jwtSection["Audience"] ?? "Billister.Mobile";
        var key = jwtSection["Key"] ?? "DEV_ONLY_CHANGE_ME_please_use_user_secrets_or_env";
        return (issuer, audience, key);
    }

    public string CreateAccessToken(ApplicationUser user, IList<string> roles)
    {
        var (issuer, audience, key) = GetJwtConfig();

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
            new(JwtRegisteredClaimNames.UniqueName, user.UserName ?? string.Empty),
            new(ClaimTypes.NameIdentifier, user.Id.ToString())
        };

        // Add role claims
        foreach (var role in roles)
        {
            claims.Add(new Claim(ClaimTypes.Role, role));
        }

        var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key));
        var creds = new SigningCredentials(signingKey, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(15), // Short lived access token
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public string CreateRefreshToken(ApplicationUser user, IList<string> roles)
    {
        var (issuer, audience, key) = GetJwtConfig();

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
            new(JwtRegisteredClaimNames.UniqueName, user.UserName ?? string.Empty),
            new(ClaimTypes.NameIdentifier, user.Id.ToString())
        };

        // Add role claims
        foreach (var role in roles)
        {
            claims.Add(new Claim(ClaimTypes.Role, role));
        }

        var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key));
        var creds = new SigningCredentials(signingKey, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: DateTime.UtcNow.AddDays(7), // Long lived refresh token
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public (bool isValid, string? userId, string? email, string? username, IList<string>? roles) ValidateRefreshToken(string token)
    {
        try
        {
            var (issuer, audience, key) = GetJwtConfig();
            var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key));

            var tokenHandler = new JwtSecurityTokenHandler();
            var principal = tokenHandler.ValidateToken(token, new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = signingKey,
                ValidateIssuer = true,
                ValidIssuer = issuer,
                ValidateAudience = true,
                ValidAudience = audience,
                ValidateLifetime = true,
                ClockSkew = TimeSpan.Zero
            }, out SecurityToken validatedToken);

            var userId = principal.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;
            var email = principal.FindFirst(JwtRegisteredClaimNames.Email)?.Value;
            var username = principal.FindFirst(JwtRegisteredClaimNames.UniqueName)?.Value;
            var roles = principal.FindAll(ClaimTypes.Role).Select(c => c.Value).ToList();

            return (true, userId, email, username, roles);
        }
        catch
        {
            return (false, null, null, null, null);
        }
    }
}
