using Billister.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace Billister.Controllers;

[ApiController]
[Route("api/admin")]
[Authorize(Roles = "Admin")]
public sealed class AdminController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly RoleManager<ApplicationRole> _roleManager;

    public AdminController(
        UserManager<ApplicationUser> userManager,
        RoleManager<ApplicationRole> roleManager)
    {
        _userManager = userManager;
        _roleManager = roleManager;
    }

    [HttpPost("users/{userId}/promote")]
    public async Task<IActionResult> PromoteUserToAdmin(Guid userId)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString());
        if (user is null)
        {
            return NotFound(new { message = "User not found" });
        }

        // Check if already admin
        if (await _userManager.IsInRoleAsync(user, "Admin"))
        {
            return BadRequest(new { message = "User is already an admin" });
        }

        // Remove User role if exists
        if (await _userManager.IsInRoleAsync(user, "User"))
        {
            await _userManager.RemoveFromRoleAsync(user, "User");
        }

        // Add Admin role
        var result = await _userManager.AddToRoleAsync(user, "Admin");
        if (!result.Succeeded)
        {
            return BadRequest(new { errors = result.Errors.Select(e => e.Description) });
        }

        return Ok(new { message = $"User {user.Email} promoted to Admin" });
    }

    [HttpPost("users/{userId}/demote")]
    public async Task<IActionResult> DemoteAdminToUser(Guid userId)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString());
        if (user is null)
        {
            return NotFound(new { message = "User not found" });
        }

        // Check if is admin
        if (!await _userManager.IsInRoleAsync(user, "Admin"))
        {
            return BadRequest(new { message = "User is not an admin" });
        }

        // Remove Admin role
        var result = await _userManager.RemoveFromRoleAsync(user, "Admin");
        if (!result.Succeeded)
        {
            return BadRequest(new { errors = result.Errors.Select(e => e.Description) });
        }

        // Add User role
        await _userManager.AddToRoleAsync(user, "User");

        return Ok(new { message = $"User {user.Email} demoted to User" });
    }

    [HttpGet("users")]
    public async Task<IActionResult> GetAllUsers()
    {
        var users = _userManager.Users.ToList();
        var userDtos = new List<object>();

        foreach (var user in users)
        {
            var roles = await _userManager.GetRolesAsync(user);
            userDtos.Add(new
            {
                id = user.Id,
                email = user.Email,
                username = user.UserName,
                roles = roles
            });
        }

        return Ok(userDtos);
    }

    [HttpGet("users/{userId}/roles")]
    public async Task<IActionResult> GetUserRoles(Guid userId)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString());
        if (user is null)
        {
            return NotFound(new { message = "User not found" });
        }

        var roles = await _userManager.GetRolesAsync(user);
        return Ok(new { userId = user.Id, email = user.Email, roles = roles });
    }
}
