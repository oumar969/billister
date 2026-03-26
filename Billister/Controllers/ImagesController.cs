using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Billister.Controllers;

[ApiController]
[Route("api/images")]
public sealed class ImagesController : ControllerBase
{
    private readonly IWebHostEnvironment _env;

    private static readonly HashSet<string> AllowedContentTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        "image/jpeg",
        "image/jpg",
        "image/png",
        "image/webp",
        "image/heic",
        "image/heif",
    };

    private static readonly Dictionary<string, string> ContentTypeToExtension =
        new(StringComparer.OrdinalIgnoreCase)
        {
            ["image/jpeg"] = ".jpg",
            ["image/jpg"] = ".jpg",
            ["image/png"] = ".png",
            ["image/webp"] = ".webp",
            ["image/heic"] = ".heic",
            ["image/heif"] = ".heif",
        };

    public ImagesController(IWebHostEnvironment env)
    {
        _env = env;
    }

    /// <summary>
    /// Uploads a single image and returns its public URL.
    /// Accepts multipart/form-data with a field named "file".
    /// </summary>
    [Authorize]
    [HttpPost("upload")]
    [RequestSizeLimit(10 * 1024 * 1024)] // 10 MB
    public async Task<ActionResult<object>> Upload(
        IFormFile file,
        CancellationToken ct)
    {
        if (file is null || file.Length == 0)
            return BadRequest(new { error = "Ingen fil modtaget." });

        if (!AllowedContentTypes.Contains(file.ContentType))
            return BadRequest(new { error = "Kun JPEG, PNG, WebP og HEIC billeder er tilladt." });

        var ext = ContentTypeToExtension.GetValueOrDefault(file.ContentType, ".jpg");

        var webRoot = string.IsNullOrEmpty(_env.WebRootPath)
            ? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot")
            : _env.WebRootPath;

        var imagesDir = Path.Combine(webRoot, "images");
        Directory.CreateDirectory(imagesDir);

        var fileName = $"{Guid.NewGuid()}{ext}";
        var filePath = Path.Combine(imagesDir, fileName);

        await using var stream = new FileStream(
            filePath, FileMode.Create, FileAccess.Write, FileShare.None);
        await file.CopyToAsync(stream, ct);

        var url = $"{Request.Scheme}://{Request.Host}/images/{fileName}";
        return Ok(new { url });
    }
}
