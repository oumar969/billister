using Billister.Models;
using Billister.Services;
using Billister.Contracts;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Identity;

namespace Billister.Controllers;

[ApiController]
[Route("api/auth")]
public sealed class AuthController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly SignInManager<ApplicationUser> _signInManager;
    private readonly IJwtTokenService _jwt;
    private readonly IInputValidationService _validation;

    public AuthController(
        UserManager<ApplicationUser> userManager,
        SignInManager<ApplicationUser> signInManager,
        IJwtTokenService jwt,
        IInputValidationService validation)
    {
        _userManager = userManager;
        _signInManager = signInManager;
        _jwt = jwt;
        _validation = validation;
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
}
