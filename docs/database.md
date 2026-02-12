
# Database (EF Core)

Projektet bruger EF Core + SQLite som standard i udvikling.

## Connection string

Default ligger i [Billister/appsettings.json](../Billister/appsettings.json):

- `ConnectionStrings:Default` → `Data Source=billister.db`

## Migrations (anbefalet)

Når du har .NET SDK installeret på maskinen:

```powershell
cd "C:\Users\oamma\OneDrive\Desktop\Ny mappe (2)\billister"

dotnet tool install --global dotnet-ef
# eller: dotnet tool update --global dotnet-ef

dotnet restore

# Opret første migration
dotnet ef migrations add InitialCreate --project .\Billister\Billister.csproj

# Apply til lokal DB
dotnet ef database update --project .\Billister\Billister.csproj
```

Appen kører automatisk `db.Database.Migrate()` ved startup hvis der findes migrations. Hvis der ikke findes migrations endnu, falder den tilbage til `EnsureCreated()` (dev convenience).

## Noter

- I prod bør du typisk kun bruge migrations (ikke `EnsureCreated`).
- Hvis du skifter DB (SQL Server/Postgres), kan connection string + provider ændres i `Program.cs` og `BillisterDbContextFactory`.
