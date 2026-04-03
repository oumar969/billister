using Billister.Models;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace Billister.Data;

public sealed class BillisterDbContext
    : IdentityDbContext<ApplicationUser, ApplicationRole, Guid>
{
    public BillisterDbContext(DbContextOptions<BillisterDbContext> options) : base(options)
    {
    }

    public DbSet<CarListing> CarListings => Set<CarListing>();
    public DbSet<CarImage> CarImages => Set<CarImage>();
    public DbSet<VehicleMake> VehicleMakes => Set<VehicleMake>();
    public DbSet<VehicleModel> VehicleModels => Set<VehicleModel>();
    public DbSet<ListingView> ListingViews => Set<ListingView>();
    public DbSet<Favorite> Favorites => Set<Favorite>();
    public DbSet<SavedSearch> SavedSearches => Set<SavedSearch>();
    public DbSet<DeviceToken> DeviceTokens => Set<DeviceToken>();
    public DbSet<SearchMatchNotification> SearchMatchNotifications => Set<SearchMatchNotification>();
    public DbSet<ChatThread> ChatThreads => Set<ChatThread>();
    public DbSet<ChatMessage> ChatMessages => Set<ChatMessage>();
    public DbSet<Review> Reviews => Set<Review>();
    public DbSet<SellerRating> SellerRatings => Set<SellerRating>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<LicensePlateLookupCache> LicensePlateLookupCaches => Set<LicensePlateLookupCache>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.Entity<CarListing>(b =>
        {
            b.HasKey(x => x.Id);
            b.HasIndex(x => x.CreatedAtUtc);
            b.HasIndex(x => new { x.Make, x.Model });

            b.Property(x => x.Make).HasMaxLength(80);
            b.Property(x => x.Model).HasMaxLength(80);
            b.Property(x => x.Variant).HasMaxLength(120);
            b.Property(x => x.FuelType).HasMaxLength(30);
            b.Property(x => x.Transmission).HasMaxLength(30);
            b.Property(x => x.BodyType).HasMaxLength(30);
            b.Property(x => x.Color).HasMaxLength(30);
            b.Property(x => x.Description).HasMaxLength(8000);
            b.Property(x => x.SellerPhone).HasMaxLength(30);

            b.Property(x => x.FeaturesJson).HasDefaultValue("[]");
            b.Property(x => x.ExtraAttributesJson).HasDefaultValue("{}");

            b.HasMany(x => x.Images)
                .WithOne(x => x.Listing)
                .HasForeignKey(x => x.ListingId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        builder.Entity<CarImage>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.Url).HasMaxLength(2048);
            b.HasIndex(x => new { x.ListingId, x.SortOrder });
        });

        builder.Entity<VehicleMake>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.Name).HasMaxLength(120);
            b.HasIndex(x => x.Name).IsUnique();

            b.HasMany(x => x.Models)
                .WithOne(x => x.Make)
                .HasForeignKey(x => x.MakeId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        builder.Entity<VehicleModel>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.Name).HasMaxLength(120);
            b.HasIndex(x => new { x.MakeId, x.Name }).IsUnique();
        });

        builder.Entity<Favorite>(b =>
        {
            b.HasKey(x => new { x.UserId, x.ListingId });
            b.HasIndex(x => x.ListingId);
        });

        builder.Entity<SavedSearch>(b =>
        {
            b.HasKey(x => x.Id);
            b.HasIndex(x => x.UserId);
            b.Property(x => x.Name).HasMaxLength(120);
            b.Property(x => x.CriteriaJson).HasMaxLength(20000);
        });

        builder.Entity<DeviceToken>(b =>
        {
            b.HasKey(x => x.Id);
            b.HasIndex(x => new { x.UserId, x.Platform });
            b.Property(x => x.Token).HasMaxLength(4096);
            b.Property(x => x.Platform).HasMaxLength(20);
        });

        builder.Entity<SearchMatchNotification>(b =>
        {
            b.HasKey(x => x.Id);
            b.HasIndex(x => new { x.UserId, x.CreatedAtUtc });
        });

        builder.Entity<ChatThread>(b =>
        {
            b.HasKey(x => x.Id);
            b.HasIndex(x => new { x.ListingId, x.BuyerId, x.SellerId }).IsUnique();
        });

        builder.Entity<ListingView>(b =>
        {
            b.HasKey(x => x.Id);
            b.HasIndex(x => new { x.ListingId, x.CreatedAtUtc });
        });

        builder.Entity<Review>(b =>
        {
            b.HasKey(x => x.Id);
            b.HasIndex(x => x.ListingId);
            b.HasIndex(x => x.SellerUserId);
            b.HasIndex(x => x.BuyerUserId);
            b.HasIndex(x => new { x.SellerUserId, x.CreatedAtUtc });

            b.Property(x => x.Rating).IsRequired();
            b.Property(x => x.Title).HasMaxLength(200);
            b.Property(x => x.Comment).HasMaxLength(2000);

            // Foreign keys
            b.HasOne(x => x.Listing)
                .WithMany()
                .HasForeignKey(x => x.ListingId)
                .OnDelete(DeleteBehavior.Restrict);

            b.HasOne(x => x.Seller)
                .WithMany()
                .HasForeignKey(x => x.SellerUserId)
                .OnDelete(DeleteBehavior.Restrict);

            b.HasOne(x => x.Buyer)
                .WithMany()
                .HasForeignKey(x => x.BuyerUserId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        builder.Entity<SellerRating>(b =>
        {
            b.HasKey(x => x.SellerId);
            b.HasOne(x => x.Seller)
                .WithOne()
                .HasForeignKey<SellerRating>(x => x.SellerId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        builder.Entity<ChatMessage>(b =>
        {
            b.HasKey(x => x.Id);
            b.HasIndex(x => x.ChatThreadId);
            b.HasIndex(x => new { x.ChatThreadId, x.CreatedAtUtc });
            b.HasIndex(x => new { x.SenderId, x.CreatedAtUtc });

            b.Property(x => x.Content).IsRequired().HasMaxLength(5000);

            // Foreign keys
            b.HasOne(x => x.ChatThread)
                .WithMany()
                .HasForeignKey(x => x.ChatThreadId)
                .OnDelete(DeleteBehavior.Cascade);

            b.HasOne(x => x.Sender)
                .WithMany()
                .HasForeignKey(x => x.SenderId)
                .OnDelete(DeleteBehavior.Restrict);

            b.HasOne(x => x.Receiver)
                .WithMany()
                .HasForeignKey(x => x.ReceiverId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        builder.Entity<Order>(b =>
        {
            b.HasKey(x => x.Id);
            b.HasIndex(x => x.ListingId);
            b.HasIndex(x => x.BuyerId);
            b.HasIndex(x => x.SellerId);
            b.HasIndex(x => new { x.BuyerId, x.CreatedAtUtc });

            b.Property(x => x.Status).HasMaxLength(30);
            b.Property(x => x.Amount).HasPrecision(18, 2);

            // Foreign keys
            b.HasOne(x => x.Listing)
                .WithMany()
                .HasForeignKey(x => x.ListingId)
                .OnDelete(DeleteBehavior.Restrict);

            b.HasOne(x => x.Buyer)
                .WithMany()
                .HasForeignKey(x => x.BuyerId)
                .OnDelete(DeleteBehavior.Restrict);

            b.HasOne(x => x.Seller)
                .WithMany()
                .HasForeignKey(x => x.SellerId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        builder.Entity<Payment>(b =>
        {
            b.HasKey(x => x.Id);
            b.HasIndex(x => x.OrderId);
            b.HasIndex(x => x.ExternalPaymentId).IsUnique();
            b.HasIndex(x => new { x.Status, x.CreatedAtUtc });

            b.Property(x => x.Status).HasMaxLength(30);
            b.Property(x => x.Provider).HasMaxLength(50);
            b.Property(x => x.Amount).HasPrecision(18, 2);

            // Foreign key
            b.HasOne(x => x.Order)
                .WithMany()
                .HasForeignKey(x => x.OrderId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }
}
