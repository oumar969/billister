using System;
using Billister.Data;
using Microsoft.EntityFrameworkCore.Migrations;
using Microsoft.EntityFrameworkCore.Infrastructure;

#nullable disable

namespace Billister.Migrations
{
    /// <inheritdoc />
    [DbContext(typeof(BillisterDbContext))]
    [Migration("20260212220000_SeedDemoListings")]
    public partial class SeedDemoListings : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Seed a small set of demo listings with images.
            // Uses INSERT ... WHERE NOT EXISTS so it's safe to apply on an existing DB.

            migrationBuilder.Sql("""
INSERT INTO CarListings (
    Id,
    SellerUserId,
    Make,
    Model,
    Variant,
    Year,
    MileageKm,
    PriceDkk,
    FuelType,
    Transmission,
    City,
    PostalCode,
    Title,
    Description,
    FeaturesJson,
    ExtraAttributesJson,
    ViewCount,
    FavoriteCount,
    CreatedAtUtc,
    UpdatedAtUtc
)
SELECT
    '11111111-1111-1111-1111-111111111111',
    '00000000-0000-0000-0000-000000000001',
    'BMW',
    '3-Serie',
    '320d',
    2019,
    85000,
    299900,
    'diesel',
    'automat',
    'København',
    '2100',
    'BMW 320d 2019 – Velholdt',
    'Pæn og velholdt BMW 320d med automatgear. Klar til levering.',
    '["navigation","adaptiv_fartpilot"]',
    '{"condition":"used"}',
    0,
    0,
    '2026-02-12T00:00:00Z',
    NULL
WHERE NOT EXISTS (SELECT 1 FROM CarListings WHERE Id = '11111111-1111-1111-1111-111111111111');

INSERT INTO CarListings (
    Id,
    SellerUserId,
    Make,
    Model,
    Variant,
    Year,
    MileageKm,
    PriceDkk,
    FuelType,
    Transmission,
    City,
    PostalCode,
    Title,
    Description,
    FeaturesJson,
    ExtraAttributesJson,
    ViewCount,
    FavoriteCount,
    CreatedAtUtc,
    UpdatedAtUtc
)
SELECT
    '22222222-2222-2222-2222-222222222222',
    '00000000-0000-0000-0000-000000000001',
    'Tesla',
    'Model 3',
    'Long Range',
    2021,
    42000,
    319900,
    'el',
    'automat',
    'Aarhus',
    '8000',
    'Tesla Model 3 Long Range',
    'Elbil med lang rækkevidde og masser af udstyr.',
    '["varmepumpe","autopilot"]',
    '{"condition":"used"}',
    0,
    0,
    '2026-02-12T00:00:00Z',
    NULL
WHERE NOT EXISTS (SELECT 1 FROM CarListings WHERE Id = '22222222-2222-2222-2222-222222222222');

INSERT INTO CarListings (
    Id,
    SellerUserId,
    Make,
    Model,
    Variant,
    Year,
    MileageKm,
    PriceDkk,
    FuelType,
    Transmission,
    City,
    PostalCode,
    Title,
    Description,
    FeaturesJson,
    ExtraAttributesJson,
    ViewCount,
    FavoriteCount,
    CreatedAtUtc,
    UpdatedAtUtc
)
SELECT
    '33333333-3333-3333-3333-333333333333',
    '00000000-0000-0000-0000-000000000001',
    'Volkswagen',
    'Golf',
    '1.5 TSI',
    2018,
    97000,
    169900,
    'benzin',
    'manuel',
    'Odense',
    '5000',
    'VW Golf 1.5 TSI',
    'Økonomisk og rummelig hatchback. Service ok.',
    '["apple_carplay"]',
    '{"condition":"used"}',
    0,
    0,
    '2026-02-12T00:00:00Z',
    NULL
WHERE NOT EXISTS (SELECT 1 FROM CarListings WHERE Id = '33333333-3333-3333-3333-333333333333');

INSERT INTO CarImages (
    Id,
    ListingId,
    Url,
    SortOrder,
    Width,
    Height,
    CreatedAtUtc
)
SELECT
    'aaaaaaa1-aaaa-aaaa-aaaa-aaaaaaaaaaa1',
    '11111111-1111-1111-1111-111111111111',
    'https://placehold.co/800x600?text=BMW+320d',
    0,
    800,
    600,
    '2026-02-12T00:00:00Z'
WHERE NOT EXISTS (SELECT 1 FROM CarImages WHERE Id = 'aaaaaaa1-aaaa-aaaa-aaaa-aaaaaaaaaaa1');

INSERT INTO CarImages (
    Id,
    ListingId,
    Url,
    SortOrder,
    Width,
    Height,
    CreatedAtUtc
)
SELECT
    'aaaaaaa4-aaaa-aaaa-aaaa-aaaaaaaaaaa4',
    '11111111-1111-1111-1111-111111111111',
    'https://placehold.co/800x600?text=BMW+320d+%232',
    1,
    800,
    600,
    '2026-02-12T00:00:00Z'
WHERE NOT EXISTS (SELECT 1 FROM CarImages WHERE Id = 'aaaaaaa4-aaaa-aaaa-aaaa-aaaaaaaaaaa4');

INSERT INTO CarImages (
    Id,
    ListingId,
    Url,
    SortOrder,
    Width,
    Height,
    CreatedAtUtc
)
SELECT
    'aaaaaaa2-aaaa-aaaa-aaaa-aaaaaaaaaaa2',
    '22222222-2222-2222-2222-222222222222',
    'https://placehold.co/800x600?text=Tesla+Model+3',
    0,
    800,
    600,
    '2026-02-12T00:00:00Z'
WHERE NOT EXISTS (SELECT 1 FROM CarImages WHERE Id = 'aaaaaaa2-aaaa-aaaa-aaaa-aaaaaaaaaaa2');

INSERT INTO CarImages (
    Id,
    ListingId,
    Url,
    SortOrder,
    Width,
    Height,
    CreatedAtUtc
)
SELECT
    'aaaaaaa5-aaaa-aaaa-aaaa-aaaaaaaaaaa5',
    '22222222-2222-2222-2222-222222222222',
    'https://placehold.co/800x600?text=Tesla+Model+3+%232',
    1,
    800,
    600,
    '2026-02-12T00:00:00Z'
WHERE NOT EXISTS (SELECT 1 FROM CarImages WHERE Id = 'aaaaaaa5-aaaa-aaaa-aaaa-aaaaaaaaaaa5');

INSERT INTO CarImages (
    Id,
    ListingId,
    Url,
    SortOrder,
    Width,
    Height,
    CreatedAtUtc
)
SELECT
    'aaaaaaa3-aaaa-aaaa-aaaa-aaaaaaaaaaa3',
    '33333333-3333-3333-3333-333333333333',
    'https://placehold.co/800x600?text=VW+Golf',
    0,
    800,
    600,
    '2026-02-12T00:00:00Z'
WHERE NOT EXISTS (SELECT 1 FROM CarImages WHERE Id = 'aaaaaaa3-aaaa-aaaa-aaaa-aaaaaaaaaaa3');

INSERT INTO CarImages (
    Id,
    ListingId,
    Url,
    SortOrder,
    Width,
    Height,
    CreatedAtUtc
)
SELECT
    'aaaaaaa6-aaaa-aaaa-aaaa-aaaaaaaaaaa6',
    '33333333-3333-3333-3333-333333333333',
    'https://placehold.co/800x600?text=VW+Golf+%232',
    1,
    800,
    600,
    '2026-02-12T00:00:00Z'
WHERE NOT EXISTS (SELECT 1 FROM CarImages WHERE Id = 'aaaaaaa6-aaaa-aaaa-aaaa-aaaaaaaaaaa6');
""");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
DELETE FROM CarImages WHERE Id IN (
    'aaaaaaa1-aaaa-aaaa-aaaa-aaaaaaaaaaa1',
    'aaaaaaa2-aaaa-aaaa-aaaa-aaaaaaaaaaa2',
    'aaaaaaa3-aaaa-aaaa-aaaa-aaaaaaaaaaa3',
    'aaaaaaa4-aaaa-aaaa-aaaa-aaaaaaaaaaa4',
    'aaaaaaa5-aaaa-aaaa-aaaa-aaaaaaaaaaa5',
    'aaaaaaa6-aaaa-aaaa-aaaa-aaaaaaaaaaa6'
);

DELETE FROM CarListings WHERE Id IN (
    '11111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222',
    '33333333-3333-3333-3333-333333333333'
);
""");
        }
    }
}
