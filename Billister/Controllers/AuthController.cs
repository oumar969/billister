using Billister.Models;
using Billister.Services;
using Billister.Contracts;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Authorization;

namespace Billister.Controllers;

[ApiController]
[Route("api/auth")]
public sealed class AuthController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly SignInManager<ApplicationUser> _signInManager;
    private readonly IJwtTokenService _jwt;
    private readonly IInputValidationService _validation;
    private readonly IEmailService _emailService;

    public AuthController(
        UserManager<ApplicationUser> userManager,
        SignInManager<ApplicationUser> signInManager,
        IJwtTokenService jwt,
        IInputValidationService validation,
        IEmailService emailService)
    {
        _userManager = userManager;
        _signInManager = signInManager;
        _jwt = jwt;
        _validation = validation;
        _emailService = emailService;
    }

    [HttpPost("register")]
    public async Task<ActionResult<ApiDtos.Auth.AuthResponse>> Register([FromBody] ApiDtos.Auth.RegisterRequest req)
    {
        // Validate input
        var usernameValidation = _validation.ValidateUsername(req.Username);
        if (!usernameValidation.IsValid)
            return BadRequest(new { error = usernameValidation.ErrorMessage });

        var emailValidation = _validation.ValidateEmail(req.Email);
        if (!emailValidation.IsValid)
            return BadRequest(new { error = emailValidation.ErrorMessage });

        var passwordValidation = _validation.ValidatePassword(req.Password);
        if (!passwordValidation.IsValid)
            return BadRequest(new { error = passwordValidation.ErrorMessage });

        // Check if username already exists
        var existingUserByUsername = await _userManager.FindByNameAsync(req.Username);
        if (existingUserByUsername != null)
            return BadRequest(new { error = "Brugernavn er allerede taget" });

        // Check if email already exists
        var existingUserByEmail = await _userManager.FindByEmailAsync(req.Email);
        if (existingUserByEmail != null)
            return BadRequest(new { error = "Email er allerede registreret" });

        var user = new ApplicationUser
        {
            UserName = req.Username,
            Email = req.Email,
            EmailConfirmed = false // Requires email verification
        };

        var result = await _userManager.CreateAsync(user, req.Password);
        if (!result.Succeeded)
        {
            var errors = string.Join(", ", result.Errors.Select(e => e.Description));
            return BadRequest(new { error = errors });
        }

        // Assign user role by default
        await _userManager.AddToRoleAsync(user, "User");

        // Generate and store verification code
        var verificationCode = _jwt.CreateVerificationCode();
        user.VerificationCode = verificationCode;
        user.VerificationCodeExpiry = DateTime.UtcNow.AddMinutes(15); // 15-minute expiry
        await _userManager.UpdateAsync(user);

        // Send verification email
        await _emailService.SendVerificationEmailAsync(user.Email ?? string.Empty, verificationCode);

        var roles = await _userManager.GetRolesAsync(user);
        var accessToken = _jwt.CreateAccessToken(user, roles);
        var refreshToken = _jwt.CreateRefreshToken(user, roles);

        var userDto = new ApiDtos.Auth.UserDto(
            user.Id,
            user.Email ?? string.Empty,
            user.UserName ?? string.Empty,
            roles.ToList());

        return Ok(new ApiDtos.Auth.AuthResponse(accessToken, refreshToken, userDto));
    }

    [HttpPost("login")]
    public async Task<ActionResult<ApiDtos.Auth.AuthResponse>> Login([FromBody] ApiDtos.Auth.LoginRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Email) || string.IsNullOrWhiteSpace(req.Password))
            return BadRequest(new { error = "Email og adgangskode er påkrævet" });

        var user = await _userManager.FindByEmailAsync(req.Email);
        if (user is null)
            return Unauthorized(new { error = "Ugyldigt email eller adgangskode" });

        var result = await _signInManager.CheckPasswordSignInAsync(user, req.Password, lockoutOnFailure: true);
        if (!result.Succeeded)
        {
            if (result.IsLockedOut)
                return Unauthorized(new { error = "Konto er låst. Prøv igen senere" });

            return Unauthorized(new { error = "Ugyldigt email eller adgangskode" });
        }

        var roles = await _userManager.GetRolesAsync(user);
        var accessToken = _jwt.CreateAccessToken(user, roles);
        var refreshToken = _jwt.CreateRefreshToken(user, roles);

        var userDto = new ApiDtos.Auth.UserDto(
            user.Id,
            user.Email ?? string.Empty,
            user.UserName ?? string.Empty,
            roles.ToList());

        return Ok(new ApiDtos.Auth.AuthResponse(accessToken, refreshToken, userDto));
    }

    [HttpPost("refresh")]
    public async Task<ActionResult<ApiDtos.Auth.AuthResponse>> RefreshToken([FromBody] ApiDtos.Auth.RefreshTokenRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.RefreshToken))
            return BadRequest(new { error = "Refresh token er påkrævet" });

        var (isValid, userId, email, username, roles) = _jwt.ValidateRefreshToken(req.RefreshToken);

        if (!isValid || string.IsNullOrEmpty(userId))
            return Unauthorized(new { error = "Ugyldig eller udløbet refresh token" });

        var user = await _userManager.FindByIdAsync(userId);
        if (user is null)
            return Unauthorized(new { error = "Bruger ikke fundet" });

        // Generate new tokens
        var userRoles = await _userManager.GetRolesAsync(user);
        var accessToken = _jwt.CreateAccessToken(user, userRoles);
        var newRefreshToken = _jwt.CreateRefreshToken(user, userRoles);

        var userDto = new ApiDtos.Auth.UserDto(
            user.Id,
            user.Email ?? string.Empty,
            user.UserName ?? string.Empty,
            userRoles.ToList());

        return Ok(new ApiDtos.Auth.AuthResponse(accessToken, newRefreshToken, userDto));
    }

    [Authorize]
    [HttpPost("verify-email")]
    public async Task<IActionResult> VerifyEmail([FromBody] ApiDtos.Auth.VerifyEmailRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Code))
            return BadRequest(new { error = "Verifikationskode er påkrævet" });

        // Get the current user from claims
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
            return Unauthorized(new { error = "Bruger ikke fundet" });

        var user = await _userManager.FindByIdAsync(userId.ToString());
        if (user is null)
            return Unauthorized(new { error = "Bruger ikke fundet" });

        // Validate code format
        if (req.Code.Length != 6 || !req.Code.All(char.IsDigit))
            return BadRequest(new { error = "Ugyldigt format på verifikationskode" });

        // Validate against stored code
        if (string.IsNullOrEmpty(user.VerificationCode))
            return BadRequest(new { error = "Ingen verifikationskode anmodet" });

        if (user.VerificationCode != req.Code)
            return BadRequest(new { error = "Forkert verifikationskode" });

        // Check if code has expired (15 minutes)
        if (user.VerificationCodeExpiry.HasValue && DateTime.UtcNow > user.VerificationCodeExpiry)
            return BadRequest(new { error = "Verifikationskoden er udløbet. Anmod en ny kode." });

        // Mark email as confirmed and clear the code
        user.EmailConfirmed = true;
        user.VerificationCode = null;
        user.VerificationCodeExpiry = null;
        await _userManager.UpdateAsync(user);

        return Ok(new { message = "Email er bekræftet" });
    }

    [HttpPost("resend-verification")]
    public async Task<IActionResult> ResendVerification([FromBody] ApiDtos.Auth.ResendVerificationRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Email))
            return BadRequest(new { error = "Email er påkrævet" });

        var user = await _userManager.FindByEmailAsync(req.Email);
        if (user is null)
            return BadRequest(new { error = "Bruger ikke fundet" });

        if (user.EmailConfirmed)
            return Ok(new { message = "Email er allerede bekræftet" });

        var code = _jwt.CreateVerificationCode();
        user.VerificationCode = code;
        user.VerificationCodeExpiry = DateTime.UtcNow.AddMinutes(15); // 15-minute expiry
        await _userManager.UpdateAsync(user);

        await _emailService.SendVerificationEmailAsync(user.Email ?? string.Empty, code);

        return Ok(new { message = "Verifikationskode er sendt til email" });
    }

    [HttpPost("forgot-password")]
    public async Task<IActionResult> ForgotPassword([FromBody] ApiDtos.Auth.ForgotPasswordRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Email))
            return BadRequest(new { error = "Email er påkrævet" });

        var user = await _userManager.FindByEmailAsync(req.Email);
        if (user is null)
            // Don't reveal if user exists or not
            return Ok(new { message = "Hvis email er registreret, vil du modtage en link til at nulstille adgangskode" });

        var resetToken = _jwt.CreatePasswordResetToken(user);
        await _emailService.SendPasswordResetEmailAsync(user.Email ?? string.Empty, resetToken);

        return Ok(new { message = "Hvis email er registreret, vil du modtage en link til at nulstille adgangskode" });
    }

    [HttpPost("reset-password")]
    public async Task<IActionResult> ResetPassword([FromBody] ApiDtos.Auth.ResetPasswordRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Token) || string.IsNullOrWhiteSpace(req.NewPassword))
            return BadRequest(new { error = "Token og nye adgangskode er påkrævet" });

        var passwordValidation = _validation.ValidatePassword(req.NewPassword);
        if (!passwordValidation.IsValid)
            return BadRequest(new { error = passwordValidation.ErrorMessage });

        var (isValid, userId) = _jwt.ValidatePasswordResetToken(req.Token);
        if (!isValid || string.IsNullOrEmpty(userId))
            return BadRequest(new { error = "Ugyldigt eller udløbet nulstille-token" });

        var user = await _userManager.FindByIdAsync(userId);
        if (user is null)
            return BadRequest(new { error = "Bruger ikke fundet" });

        var removePasswordResult = await _userManager.RemovePasswordAsync(user);
        if (!removePasswordResult.Succeeded)
            return BadRequest(new { error = "Kunne ikke nulstille adgangskode" });

        var addPasswordResult = await _userManager.AddPasswordAsync(user, req.NewPassword);
        if (!addPasswordResult.Succeeded)
        {
            var errors = string.Join(", ", addPasswordResult.Errors.Select(e => e.Description));
            return BadRequest(new { error = errors });
        }

        return Ok(new { message = "Adgangskode er nulstillet. Du kan nu logge ind med din nye adgangskode" });
    }

    [Authorize]
    [HttpPost("change-password")]
    public async Task<IActionResult> ChangePassword([FromBody] ApiDtos.Auth.ChangePasswordRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.CurrentPassword) || string.IsNullOrWhiteSpace(req.NewPassword))
            return BadRequest(new { error = "Nuværende og ny adgangskode er påkrævet" });

        var passwordValidation = _validation.ValidatePassword(req.NewPassword);
        if (!passwordValidation.IsValid)
            return BadRequest(new { error = passwordValidation.ErrorMessage });

        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
            return Unauthorized(new { error = "Bruger ikke fundet" });

        var user = await _userManager.FindByIdAsync(userId.ToString());
        if (user is null)
            return Unauthorized(new { error = "Bruger ikke fundet" });

        var result = await _userManager.ChangePasswordAsync(user, req.CurrentPassword, req.NewPassword);
        if (!result.Succeeded)
        {
            var errors = string.Join(", ", result.Errors.Select(e => e.Description));
            // Use a friendly Danish message for wrong current password
            if (result.Errors.Any(e => e.Code == "PasswordMismatch"))
                return BadRequest(new { error = "Den nuværende adgangskode er forkert" });
            return BadRequest(new { error = errors });
        }

        return Ok(new { message = "Adgangskode er ændret" });
    }
}
