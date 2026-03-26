namespace Billister.Services;

public interface IEmailService
{
    Task SendEmailAsync(string to, string subject, string htmlBody);
}

/// <summary>
/// Development email service – prints emails to the console instead of sending them.
/// Replace or configure SmtpEmailService for production use.
/// </summary>
public sealed class ConsoleEmailService : IEmailService
{
    private readonly ILogger<ConsoleEmailService> _logger;

    public ConsoleEmailService(ILogger<ConsoleEmailService> logger)
    {
        _logger = logger;
    }

    public Task SendEmailAsync(string to, string subject, string htmlBody)
    {
        _logger.LogInformation(
            "[DEV EMAIL] To: {To} | Subject: {Subject}\n{Body}",
            to, subject, htmlBody);

        return Task.CompletedTask;
    }
}
