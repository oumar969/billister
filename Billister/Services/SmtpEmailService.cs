using System.Net;
using System.Net.Mail;

namespace Billister.Services;

public sealed class SmtpEmailService : IEmailService
{
    private readonly ILogger<SmtpEmailService> _logger;
    private readonly SmtpSettings _settings;

    public SmtpEmailService(ILogger<SmtpEmailService> logger, IConfiguration configuration)
    {
        _logger = logger;
        _settings = configuration.GetSection("Smtp").Get<SmtpSettings>()
            ?? throw new InvalidOperationException("Failed to bind SMTP configuration. Ensure the 'Smtp' section is present and valid.");
    }

    public async Task SendVerificationEmailAsync(string email, string verificationCode)
    {
        var subject = "Bekræft din email – Billister";
        var body =
            $"""
            <html>
            <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
                <h2 style="color: #1a73e8;">Bekræft din email</h2>
                <p>Tak for din registrering på Billister!</p>
                <p>Brug nedenstående kode til at bekræfte din email-adresse:</p>
                <div style="background: #f5f5f5; border-radius: 8px; padding: 20px; text-align: center; margin: 20px 0;">
                    <span style="font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #1a73e8;">{verificationCode}</span>
                </div>
                <p>Koden er gyldig i 15 minutter.</p>
                <p>Hvis du ikke har registreret dig på Billister, kan du se bort fra denne email.</p>
                <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 20px 0;" />
                <p style="color: #757575; font-size: 12px;">Billister – Danmarks bilmarked</p>
            </body>
            </html>
            """;

        await SendAsync(email, subject, body);
    }

    public async Task SendPasswordResetEmailAsync(string email, string resetToken)
    {
        var subject = "Nulstil adgangskode – Billister";
        var body =
            $"""
            <html>
            <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
                <h2 style="color: #1a73e8;">Nulstil adgangskode</h2>
                <p>Vi har modtaget en anmodning om at nulstille adgangskoden til din Billister-konto.</p>
                <p>Brug nedenstående token til at nulstille din adgangskode i appen:</p>
                <div style="background: #f5f5f5; border-radius: 8px; padding: 16px; margin: 20px 0; word-break: break-all; font-family: monospace; font-size: 13px;">
                    {resetToken}
                </div>
                <p>Tokenet er gyldigt i 1 time.</p>
                <p>Hvis du ikke har anmodet om at nulstille din adgangskode, kan du se bort fra denne email. Din konto er ikke i fare.</p>
                <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 20px 0;" />
                <p style="color: #757575; font-size: 12px;">Billister – Danmarks bilmarked</p>
            </body>
            </html>
            """;

        await SendAsync(email, subject, body);
    }

    private async Task SendAsync(string toEmail, string subject, string htmlBody)
    {
        using var client = new SmtpClient(_settings.Host, _settings.Port)
        {
            EnableSsl = _settings.EnableSsl,
            Credentials = new NetworkCredential(_settings.Username, _settings.Password)
        };

        using var message = new MailMessage
        {
            From = new MailAddress(_settings.FromAddress, _settings.FromName),
            Subject = subject,
            Body = htmlBody,
            IsBodyHtml = true
        };

        message.To.Add(toEmail);

        try
        {
            await client.SendMailAsync(message);
            _logger.LogInformation("Email sent successfully: {Subject}", subject);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send email: {Subject}", subject);
            throw;
        }
    }
}

public sealed class SmtpSettings
{
    public string Host { get; set; } = string.Empty;
    public int Port { get; set; } = 587;
    public bool EnableSsl { get; set; } = true;
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string FromAddress { get; set; } = string.Empty;
    public string FromName { get; set; } = "Billister";
}
