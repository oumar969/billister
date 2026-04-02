using System.Text;
using Billister.Data;
using Billister.Models;
using Billister.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddCors(options =>
{
    options.AddPolicy(
        "DevCors",
        policy =>
            policy
                .SetIsOriginAllowed(origin =>
                {
                    if (string.IsNullOrWhiteSpace(origin)) return false;
                    if (!Uri.TryCreate(origin, UriKind.Absolute, out var uri)) return false;
                    return uri.Host is "localhost" or "127.0.0.1";
                })
                .AllowAnyHeader()
                .AllowAnyMethod());
});

builder.Services.AddDbContext<BillisterDbContext>(options =>
{
    var connectionString = builder.Configuration.GetConnectionString("Default")
        ?? "Data Source=billister.db";

    options.UseSqlite(connectionString);
});

builder.Services
    .AddIdentityCore<ApplicationUser>(options =>
    {
        options.User.RequireUniqueEmail = true;
        options.Password.RequiredLength = 8;
        options.Password.RequireDigit = true;
        options.Password.RequireNonAlphanumeric = false;
        options.Password.RequireUppercase = true;
        options.Password.RequireLowercase = true;
    })
    .AddRoles<ApplicationRole>()
    .AddEntityFrameworkStores<BillisterDbContext>()
    .AddSignInManager<SignInManager<ApplicationUser>>()
    .AddDefaultTokenProviders();

var jwtSection = builder.Configuration.GetSection("Jwt");
var jwtKey = jwtSection["Key"];
if (string.IsNullOrWhiteSpace(jwtKey))
{
    jwtKey = "DEV_ONLY_CHANGE_ME_please_use_user_secrets_or_env";
}

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtSection["Issuer"] ?? "Billister",
            ValidAudience = jwtSection["Audience"] ?? "Billister.Mobile",
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
        };
    });

builder.Services.AddAuthorization();

builder.Services.AddScoped<IJwtTokenService, JwtTokenService>();
builder.Services.AddScoped<IAiDescriptionService, AiDescriptionService>();
builder.Services.AddScoped<IMotorregisterService, MotorregisterService>();
builder.Services.AddScoped<ISavedSearchNotifier, SavedSearchNotifier>();
builder.Services.AddScoped<IInputValidationService, InputValidationService>();
builder.Services.AddScoped<IEmailService, MockEmailService>();
builder.Services.AddScoped<IReviewService, ReviewService>();
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddScoped<IPaymentService, StripePaymentService>();
builder.Services.AddScoped<IChatService, ChatService>();

// Real-time messaging with SignalR
builder.Services.AddSignalR();

// Stripe payment configuration
var stripeApiKey = builder.Configuration["Stripe:ApiKey"];
if (!string.IsNullOrEmpty(stripeApiKey))
{
    Stripe.StripeConfiguration.ApiKey = stripeApiKey;
}

var app = builder.Build();

// Dev-friendly: create/apply DB schema automatically.
// If migrations exist, apply them. Otherwise fall back to EnsureCreated.
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<BillisterDbContext>();
    if (db.Database.GetMigrations().Any())
    {
        try
        {
            db.Database.Migrate();
        }
        catch (Exception ex) when (app.Environment.IsDevelopment() && db.Database.IsSqlite())
        {
            // Dev-friendly: local SQLite can get out of sync with migrations (tables already exist).
            // We'll log and rely on the dev repair block below to add missing columns needed at runtime.
            app.Logger.LogWarning(ex, "Dev DB migrate failed; continuing with best-effort schema repair");
        }
    }
    else
    {
        db.Database.EnsureCreated();
    }

    if (app.Environment.IsDevelopment() && db.Database.IsSqlite())
    {
        // Dev-only: if the local SQLite DB got out of sync with migrations,
        // ensure newly added columns exist to avoid runtime 500s.
        await using var conn = db.Database.GetDbConnection();
        await conn.OpenAsync();

        await using (var cmd = conn.CreateCommand())
        {
            cmd.CommandText = "PRAGMA table_info('CarListings');";
            await using var reader = await cmd.ExecuteReaderAsync();

            var hasSellerPhone = false;
            var hasIsSold = false;
            var nameOrdinal = -1;
            while (await reader.ReadAsync())
            {
                if (nameOrdinal == -1)
                {
                    nameOrdinal = reader.GetOrdinal("name");
                }

                var name = reader.GetString(nameOrdinal);
                if (string.Equals(name, "SellerPhone", StringComparison.OrdinalIgnoreCase))
                {
                    hasSellerPhone = true;
                    continue;
                }

                if (string.Equals(name, "IsSold", StringComparison.OrdinalIgnoreCase))
                {
                    hasIsSold = true;
                }
            }

            if (!hasSellerPhone)
            {
                await using var alter = conn.CreateCommand();
                alter.CommandText = "ALTER TABLE CarListings ADD COLUMN SellerPhone TEXT NULL;";
                await alter.ExecuteNonQueryAsync();
                app.Logger.LogInformation("Dev DB repair: added missing column CarListings.SellerPhone");
            }

            if (!hasIsSold)
            {
                await using var alter = conn.CreateCommand();
                alter.CommandText = "ALTER TABLE CarListings ADD COLUMN IsSold INTEGER NOT NULL DEFAULT 0;";
                await alter.ExecuteNonQueryAsync();
                app.Logger.LogInformation("Dev DB repair: added missing column CarListings.IsSold");
            }
        }

        // Check AspNetUsers table for verification code columns
        await using (var cmd = conn.CreateCommand())
        {
            cmd.CommandText = "PRAGMA table_info('AspNetUsers');";
            await using var reader = await cmd.ExecuteReaderAsync();

            var hasVerificationCode = false;
            var hasVerificationCodeExpiry = false;
            var nameOrdinal = -1;
            while (await reader.ReadAsync())
            {
                if (nameOrdinal == -1)
                {
                    nameOrdinal = reader.GetOrdinal("name");
                }

                var name = reader.GetString(nameOrdinal);
                if (string.Equals(name, "VerificationCode", StringComparison.OrdinalIgnoreCase))
                {
                    hasVerificationCode = true;
                    continue;
                }

                if (string.Equals(name, "VerificationCodeExpiry", StringComparison.OrdinalIgnoreCase))
                {
                    hasVerificationCodeExpiry = true;
                }
            }

            if (!hasVerificationCode)
            {
                await using var alter = conn.CreateCommand();
                alter.CommandText = "ALTER TABLE AspNetUsers ADD COLUMN VerificationCode TEXT NULL;";
                await alter.ExecuteNonQueryAsync();
                app.Logger.LogInformation("Dev DB repair: added missing column AspNetUsers.VerificationCode");
            }

            if (!hasVerificationCodeExpiry)
            {
                await using var alter = conn.CreateCommand();
                alter.CommandText = "ALTER TABLE AspNetUsers ADD COLUMN VerificationCodeExpiry TEXT NULL;";
                await alter.ExecuteNonQueryAsync();
                app.Logger.LogInformation("Dev DB repair: added missing column AspNetUsers.VerificationCodeExpiry");
            }
        }
    }

    if (app.Environment.IsDevelopment())
    {
        var devAdminEmail = builder.Configuration["DevAdmin:Email"] ?? "admin@billister.local";
        var devAdminPassword = builder.Configuration["DevAdmin:Password"] ?? "Admin";
        var devUserEmail = builder.Configuration["DevUser:Email"] ?? "user@billister.local";
        var devUserPassword = builder.Configuration["DevUser:Password"] ?? "User";

        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<ApplicationRole>>();

        // Create Admin role if it doesn't exist
        if (!await roleManager.RoleExistsAsync("Admin"))
        {
            await roleManager.CreateAsync(new ApplicationRole { Name = "Admin" });
        }

        // Create User role if it doesn't exist
        if (!await roleManager.RoleExistsAsync("User"))
        {
            await roleManager.CreateAsync(new ApplicationRole { Name = "User" });
        }

        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();

        // Create/update dev admin user
        var adminUser = await userManager.FindByEmailAsync(devAdminEmail);
        if (adminUser is null)
        {
            adminUser = new ApplicationUser
            {
                UserName = devAdminEmail,
                Email = devAdminEmail,
                EmailConfirmed = true
            };

            var createRes = await userManager.CreateAsync(adminUser, devAdminPassword);
            if (!createRes.Succeeded)
            {
                var errors = string.Join("; ", createRes.Errors.Select(e => e.Description));
                app.Logger.LogWarning("Dev admin user was not created: {Errors}", errors);
            }
        }

        if (adminUser is not null)
        {
            var resetToken = await userManager.GeneratePasswordResetTokenAsync(adminUser);
            var resetRes = await userManager.ResetPasswordAsync(adminUser, resetToken, devAdminPassword);
            if (!resetRes.Succeeded)
            {
                var errors = string.Join("; ", resetRes.Errors.Select(e => e.Description));
                app.Logger.LogWarning("Dev admin password was not updated: {Errors}", errors);
            }

            var isAdmin = await userManager.IsInRoleAsync(adminUser, "Admin");
            if (!isAdmin)
            {
                await userManager.AddToRoleAsync(adminUser, "Admin");
            }
        }

        // Create/update dev regular user
        var regularUser = await userManager.FindByEmailAsync(devUserEmail);
        if (regularUser is null)
        {
            regularUser = new ApplicationUser
            {
                UserName = devUserEmail,
                Email = devUserEmail,
                EmailConfirmed = true
            };

            var createRes = await userManager.CreateAsync(regularUser, devUserPassword);
            if (!createRes.Succeeded)
            {
                var errors = string.Join("; ", createRes.Errors.Select(e => e.Description));
                app.Logger.LogWarning("Dev user was not created: {Errors}", errors);
            }
        }

        if (regularUser is not null)
        {
            var resetToken = await userManager.GeneratePasswordResetTokenAsync(regularUser);
            var resetRes = await userManager.ResetPasswordAsync(regularUser, resetToken, devUserPassword);
            if (!resetRes.Succeeded)
            {
                var errors = string.Join("; ", resetRes.Errors.Select(e => e.Description));
                app.Logger.LogWarning("Dev user password was not updated: {Errors}", errors);
            }

            var isUser = await userManager.IsInRoleAsync(regularUser, "User");
            if (!isUser)
            {
                await userManager.AddToRoleAsync(regularUser, "User");
            }
        }
    }
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();

    app.UseCors("DevCors");
}

app.UseStaticFiles();

if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHub<Billister.Services.ChatHub>("/hubs/chat");

app.Run();
