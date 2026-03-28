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

var app = builder.Build();

// Dev-friendly: create/apply DB schema automatically.
// If migrations exist, apply them. Otherwise fall back to EnsureCreated.
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<BillisterDbContext>();
    if (db.Database.GetMigrations().Any())
    {
        db.Database.Migrate();
    }
    else
    {
        db.Database.EnsureCreated();
    }

    if (app.Environment.IsDevelopment())
    {
        var devAdminEmail = builder.Configuration["DevAdmin:Email"] ?? "admin@billister.local";
        var devAdminPassword = builder.Configuration["DevAdmin:Password"] ?? "Admin1234";

        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<ApplicationRole>>();
        if (!await roleManager.RoleExistsAsync("Admin"))
        {
            await roleManager.CreateAsync(new ApplicationRole { Name = "Admin" });
        }

        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
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
    }
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();

    app.UseCors("DevCors");
}

if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
