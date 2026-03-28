using System.Text.RegularExpressions;

namespace Billister.Services;

public interface IInputValidationService
{
    ValidationResult ValidateEmail(string email);
    ValidationResult ValidatePassword(string password);
    ValidationResult ValidateUsername(string username);
}

public sealed class ValidationResult
{
    public bool IsValid { get; set; }
    public string? ErrorMessage { get; set; }

    public static ValidationResult Success => new() { IsValid = true };
    public static ValidationResult Failure(string message) => new() { IsValid = false, ErrorMessage = message };
}

public sealed class InputValidationService : IInputValidationService
{
    public ValidationResult ValidateEmail(string email)
    {
        if (string.IsNullOrWhiteSpace(email))
            return ValidationResult.Failure("Email er påkrævet");

        email = email.Trim();

        // Basic email format check (RFC 5322 simplified)
        if (!Regex.IsMatch(email, @"^[^\s@]+@[^\s@]+\.[^\s@]+$"))
            return ValidationResult.Failure("Email format er ugyldigt");

        if (email.Length > 254)
            return ValidationResult.Failure("Email er for lang (max 254 tegn)");

        return ValidationResult.Success;
    }

    public ValidationResult ValidatePassword(string password)
    {
        if (string.IsNullOrWhiteSpace(password))
            return ValidationResult.Failure("Adgangskode er påkrævet");

        if (password.Length < 8)
            return ValidationResult.Failure("Adgangskode skal være mindst 8 tegn");

        if (password.Length > 128)
            return ValidationResult.Failure("Adgangskode er for lang (max 128 tegn)");

        bool hasDigit = password.Any(char.IsDigit);
        if (!hasDigit)
            return ValidationResult.Failure("Adgangskode skal indeholde mindst ét tal");

        bool hasUpper = password.Any(char.IsUpper);
        if (!hasUpper)
            return ValidationResult.Failure("Adgangskode skal indeholde mindst ét stort bogstav");

        bool hasLower = password.Any(char.IsLower);
        if (!hasLower)
            return ValidationResult.Failure("Adgangskode skal indeholde mindst ét lille bogstav");

        return ValidationResult.Success;
    }

    public ValidationResult ValidateUsername(string username)
    {
        if (string.IsNullOrWhiteSpace(username))
            return ValidationResult.Failure("Brugernavn er påkrævet");

        username = username.Trim();

        if (username.Length < 3)
            return ValidationResult.Failure("Brugernavn skal være mindst 3 tegn");

        if (username.Length > 50)
            return ValidationResult.Failure("Brugernavn må højst være 50 tegn");

        // Allow letters, numbers, underscore, hyphen
        if (!Regex.IsMatch(username, @"^[a-zA-Z0-9_-]+$"))
            return ValidationResult.Failure("Brugernavn kan kun indeholde bogstaver, tal, bindestreg og understreg");

        return ValidationResult.Success;
    }
}
