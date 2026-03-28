using Microsoft.Extensions.Logging;

namespace Billister.Services;

public sealed class MockEmailService : IEmailService
{
    private readonly ILogger<MockEmailService> _logger;

    public MockEmailService(ILogger<MockEmailService> logger)
    {
        _logger = logger;
    }

    public Task SendVerificationEmailAsync(string email, string verificationCode)
    {
        _logger.LogInformation(
            "📧 [MOCK EMAIL] Verification code for {Email}: {Code}",
            email,
            verificationCode);

        return Task.CompletedTask;
    }

    public Task SendPasswordResetEmailAsync(string email, string resetToken)
    {
        _logger.LogInformation(
            "📧 [MOCK EMAIL] Password reset token for {Email}: {Token}",
            email,
            resetToken);

        return Task.CompletedTask;
    }
}
