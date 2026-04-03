using Microsoft.EntityFrameworkCore;

public class HealthPulseDbContext : DbContext
{
    public HealthPulseDbContext(DbContextOptions<HealthPulseDbContext> options) : base(options)
    {
    }

    public DbSet<HealthCheck> HealthChecks => Set<HealthCheck>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<HealthCheck>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.CheckName).IsRequired().HasMaxLength(255);
            entity.Property(e => e.Status).IsRequired();
            entity.Property(e => e.CheckedAt).IsRequired();
        });
    }
}

public class HealthCheck
{
    public int Id { get; set; }
    public string CheckName { get; set; } = null!;
    public string Status { get; set; } = null!;
    public DateTime CheckedAt { get; set; }
    public string? Message { get; set; }
}
