using Billister.Services;
using Billister.Contracts;
using Microsoft.AspNetCore.Mvc;

namespace Billister.Controllers;

[ApiController]
[Route("api/feedback")]
public sealed class FeedbackController : ControllerBase
{
    private readonly IEmailService _emailService;
    private readonly ILogger<FeedbackController> _logger;

    public FeedbackController(
        IEmailService emailService,
        ILogger<FeedbackController> logger)
    {
        _emailService = emailService;
        _logger = logger;
    }

    [HttpPost]
    public async Task<ActionResult> SubmitFeedback([FromBody] ApiDtos.Feedback.SubmitFeedbackRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Idea) || string.IsNullOrWhiteSpace(req.Email))
            return BadRequest(new { error = "Idé og email er påkrævet" });

        if (req.Idea.Length < 10)
            return BadRequest(new { error = "Idéen skal være mindst 10 tegn" });

        try
        {
            // Send feedback to admin email
            // In production, you would send this to a configured feedback email
            var body = $"""
                Ny feedback indsendt:
                
                Email: {req.Email}
                
                Feedback:
                {req.Idea}
                
                Tid: {DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} UTC
                """;

            // For development, just log it
            _logger.LogInformation("Feedback received from {Email}: {Idea}", req.Email, req.Idea);

            // In production, send via email
            // var subject = "Ny feedback fra Billister app";
            // await _emailService.SendEmailAsync("feedback@billister.app", subject, body);

            return Ok(new { message = "Feedback modtaget og tak for dit input!" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error submitting feedback from {Email}", req.Email);
            return StatusCode(500, new { error = "Fejl ved indsendelse af feedback" });
        }
    }
}
