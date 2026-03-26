using System.Security.Claims;
using Billister.Contracts;
using Billister.Models;
using Billister.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace Billister.Controllers;

[ApiController]
[Authorize]
[Route("api/profile")]
public sealed class ProfileController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly IJwtTokenService _jwt;

    public ProfileController(UserManager<ApplicationUser> userManager, IJwtTokenService jwt)
    {
        _userManager = userManager;
        _jwt = jwt;
    }

    [HttpGet]
    public async Task<ActionResult<ApiDtos.Profile.GetProfileResponse>> Get()
    {
        var user = await GetCurrentUserAsync();
        if (user is null) return Unauthorized();

        return Ok(new ApiDtos.Profile.GetProfileResponse(
            Email: user.Email ?? string.Empty,
            DisplayName: user.DisplayName,
            PhoneNumber: user.PhoneNumber));
    }

    [HttpPut]
    public async Task<ActionResult<ApiDtos.Profile.UpdateProfileResponse>> Update(
        [FromBody] ApiDtos.Profile.UpdateProfileRequest req)
    {
        var user = await GetCurrentUserAsync();
        if (user is null) return Unauthorized();

        user.DisplayName = req.DisplayName?.Trim().Length > 0 ? req.DisplayName.Trim() : null;
        user.PhoneNumber = req.PhoneNumber?.Trim().Length > 0 ? req.PhoneNumber.Trim() : null;

        var result = await _userManager.UpdateAsync(user);
        if (!result.Succeeded)
        {
            return BadRequest(new { errors = result.Errors.Select(e => e.Description) });
        }

        var newToken = _jwt.CreateToken(user);
        return Ok(new ApiDtos.Profile.UpdateProfileResponse(
            Email: user.Email ?? string.Empty,
            DisplayName: user.DisplayName,
            PhoneNumber: user.PhoneNumber,
            Token: newToken));
    }

    [HttpPost("change-password")]
    public async Task<ActionResult> ChangePassword(
        [FromBody] ApiDtos.Profile.ChangePasswordRequest req)
    {
        var user = await GetCurrentUserAsync();
        if (user is null) return Unauthorized();

        var result = await _userManager.ChangePasswordAsync(user, req.CurrentPassword, req.NewPassword);
        if (!result.Succeeded)
        {
            return BadRequest(new { errors = result.Errors.Select(e => e.Description) });
        }

        return NoContent();
    }

    private async Task<ApplicationUser?> GetCurrentUserAsync()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (sub is null) return null;
        return await _userManager.FindByIdAsync(sub);
    }
}
