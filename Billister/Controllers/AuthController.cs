using Billister.Models;
using Billister.Services;
using Billister.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Identity;
using System.Security.Claims;

namespace Billister.Controllers;

[ApiController]
[Route("api/auth")]
public sealed class AuthController : ControllerBase
{
    private static readonly int AccessTokenExpiresInSeconds = (int)TimeSpan.FromMinutes(15).TotalSeconds;

    private readonly UserManager<ApplicationUser> _userManager;
    private readonly SignInManager<ApplicationUser> _signInManager;
    private readonly IJwtTokenService _jwt;
    private readonly IEmailService _email;

    public AuthController(
        UserManager<ApplicationUser> userManager,
        SignInManager<ApplicationUser> signInManager,
        IJwtTokenService jwt,
        IEmailService email)
    {
        _userManager = userManager;
        _signInManager = signInManager;
        _jwt = jwt;
        _email = email;
    }

    // POST /api/auth/register
    [HttpPost("register")]
    public async Task<ActionResult<ApiDtos.Auth.AuthResponse>> Register([FromBody] ApiDtos.Auth.RegisterRequest req)
    {
        var user = new ApplicationUser
        {
            UserName = req.Email,
            Email = req.Email
        };

        var result = await _userManager.CreateAsync(user, req.Password);
        if (!result.Succeeded)
        {
            return BadRequest(new { errors = result.Errors.Select(e => e.Description) });
        }

        // Send email verification
        var verificationToken = await _userManager.GenerateEmailConfirmationTokenAsync(user);
        await _email.SendEmailAsync(
            user.Email!,
            "Bekræft din email – Billister",
            BuildVerifyEmailBody(user.Id.ToString(), verificationToken));

        var accessToken = _jwt.CreateAccessToken(user);
        var refreshToken = await _jwt.CreateRefreshTokenAsync(user);

        return Ok(new ApiDtos.Auth.AuthResponse(accessToken, refreshToken.Token, AccessTokenExpiresInSeconds));
    }

    // POST /api/auth/login
    [HttpPost("login")]
    public async Task<ActionResult<ApiDtos.Auth.AuthResponse>> Login([FromBody] ApiDtos.Auth.LoginRequest req)
    {
        var user = await _userManager.FindByEmailAsync(req.Email);
        if (user is null)
        {
            return Unauthorized();
        }

        var result = await _signInManager.CheckPasswordSignInAsync(user, req.Password, lockoutOnFailure: true);
        if (!result.Succeeded)
        {
            return Unauthorized();
        }

        var accessToken = _jwt.CreateAccessToken(user);
        var refreshToken = await _jwt.CreateRefreshTokenAsync(user);

        return Ok(new ApiDtos.Auth.AuthResponse(accessToken, refreshToken.Token, AccessTokenExpiresInSeconds));
    }

    // POST /api/auth/refresh
    [HttpPost("refresh")]
    public async Task<ActionResult<ApiDtos.Auth.AuthResponse>> Refresh([FromBody] ApiDtos.Auth.RefreshRequest req)
    {
        var existing = await _jwt.ValidateRefreshTokenAsync(req.RefreshToken);
        if (existing is null)
        {
            return Unauthorized(new { error = "Invalid or expired refresh token." });
        }

        var user = await _userManager.FindByIdAsync(existing.UserId.ToString());
        if (user is null)
        {
            return Unauthorized();
        }

        // Rotate: revoke old, issue new
        await _jwt.RevokeRefreshTokenAsync(req.RefreshToken);
        var newRefresh = await _jwt.CreateRefreshTokenAsync(user);
        var accessToken = _jwt.CreateAccessToken(user);

        return Ok(new ApiDtos.Auth.AuthResponse(accessToken, newRefresh.Token, AccessTokenExpiresInSeconds));
    }

    // POST /api/auth/logout
    [HttpPost("logout")]
    public async Task<IActionResult> Logout([FromBody] ApiDtos.Auth.LogoutRequest req)
    {
        await _jwt.RevokeRefreshTokenAsync(req.RefreshToken);
        return NoContent();
    }

    // POST /api/auth/logout-all  (requires valid access token)
    [Authorize]
    [HttpPost("logout-all")]
    public async Task<IActionResult> LogoutAll()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId is null || !Guid.TryParse(userId, out var guid))
        {
            return Unauthorized();
        }

        await _jwt.RevokeAllRefreshTokensAsync(guid);
        return NoContent();
    }

    // POST /api/auth/verify-email
    [HttpPost("verify-email")]
    public async Task<IActionResult> VerifyEmail([FromBody] ApiDtos.Auth.VerifyEmailRequest req)
    {
        var user = await _userManager.FindByIdAsync(req.UserId);
        if (user is null)
        {
            return BadRequest(new { error = "Invalid verification link." });
        }

        var result = await _userManager.ConfirmEmailAsync(user, req.Token);
        if (!result.Succeeded)
        {
            return BadRequest(new { errors = result.Errors.Select(e => e.Description) });
        }

        return Ok(new { message = "Email bekræftet." });
    }

    // POST /api/auth/resend-verification
    [HttpPost("resend-verification")]
    public async Task<IActionResult> ResendVerification([FromBody] ApiDtos.Auth.ResendVerificationRequest req)
    {
        var user = await _userManager.FindByEmailAsync(req.Email);

        // Always return 204 to avoid user enumeration
        if (user is not null && !await _userManager.IsEmailConfirmedAsync(user))
        {
            var token = await _userManager.GenerateEmailConfirmationTokenAsync(user);
            await _email.SendEmailAsync(
                user.Email!,
                "Bekræft din email – Billister",
                BuildVerifyEmailBody(user.Id.ToString(), token));
        }

        return NoContent();
    }

    // POST /api/auth/forgot-password
    [HttpPost("forgot-password")]
    public async Task<IActionResult> ForgotPassword([FromBody] ApiDtos.Auth.ForgotPasswordRequest req)
    {
        var user = await _userManager.FindByEmailAsync(req.Email);

        // Always return 204 to avoid user enumeration
        if (user is not null)
        {
            var token = await _userManager.GeneratePasswordResetTokenAsync(user);
            await _email.SendEmailAsync(
                user.Email!,
                "Nulstil dit kodeord – Billister",
                BuildResetPasswordBody(user.Email!, token));
        }

        return NoContent();
    }

    // POST /api/auth/reset-password
    [HttpPost("reset-password")]
    public async Task<IActionResult> ResetPassword([FromBody] ApiDtos.Auth.ResetPasswordRequest req)
    {
        var user = await _userManager.FindByEmailAsync(req.Email);
        if (user is null)
        {
            return BadRequest(new { error = "Invalid request." });
        }

        var result = await _userManager.ResetPasswordAsync(user, req.Token, req.NewPassword);
        if (!result.Succeeded)
        {
            return BadRequest(new { errors = result.Errors.Select(e => e.Description) });
        }

        // Revoke all sessions after password reset
        await _jwt.RevokeAllRefreshTokensAsync(user.Id);

        return Ok(new { message = "Kodeord er nulstillet." });
    }

    private static string BuildVerifyEmailBody(string userId, string token)
    {
        var encodedToken = Uri.EscapeDataString(token);
        return $"<p>Bekræft din email ved at bruge følgende kode i appen:<br>" +
               $"<strong>Bruger-ID:</strong> {userId}<br>" +
               $"<strong>Token:</strong> {encodedToken}</p>" +
               $"<p>Tokenet udløber om 24 timer.</p>";
    }

    private static string BuildResetPasswordBody(string email, string token)
    {
        var encodedToken = Uri.EscapeDataString(token);
        return $"<p>Du har bedt om at nulstille dit kodeord.<br>" +
               $"Brug følgende token i appen:<br>" +
               $"<strong>Email:</strong> {email}<br>" +
               $"<strong>Token:</strong> {encodedToken}</p>" +
               $"<p>Tokenet udløber om 1 time. Ignorer denne email, hvis du ikke har bedt om det.</p>";
    }
}
