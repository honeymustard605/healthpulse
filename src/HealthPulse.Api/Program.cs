using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Microsoft.EntityFrameworkCore;
using OpenTelemetry.Metrics;

var builder = WebApplication.CreateBuilder(args);

// In non-dev environments, pull secrets from Azure Key Vault.
// The Key Vault URI is expected in config as "KeyVault:Uri"
// (e.g. set via AKS env var KeyVault__Uri).
// The connection string secret must be named "ConnectionStrings--DefaultConnection".
if (!builder.Environment.IsDevelopment())
{
    var keyVaultUri = builder.Configuration["KeyVault:Uri"]
        ?? throw new InvalidOperationException("KeyVault:Uri is not configured.");

    var secretClient = new SecretClient(new Uri(keyVaultUri), new DefaultAzureCredential());
    var secret = secretClient.GetSecret("ConnectionStrings--DefaultConnection");
    builder.Configuration["ConnectionStrings:DefaultConnection"] = secret.Value.Value;
}

// Add services to the container
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Configure entity framework with PostgreSQL
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");
builder.Services.AddDbContext<HealthPulseDbContext>(options =>
    options.UseNpgsql(connectionString));

// Configure OpenTelemetry for Prometheus
builder.Services.AddOpenTelemetry()
    .WithMetrics(metrics =>
    {
        metrics
            .AddAspNetCoreInstrumentation()
            .AddPrometheusExporter();
    });

var app = builder.Build();

// Apply pending migrations on startup
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<HealthPulseDbContext>();
    db.Database.Migrate();
}

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseExceptionHandler();
app.UseHttpsRedirection();

// Health check endpoint
app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }))
    .WithName("HealthCheck")
    .WithOpenApi();

// Status endpoint
app.MapGet("/api/status", async (HealthPulseDbContext db) =>
{
    try
    {
        // Check database connectivity
        var dbHealthy = await db.Database.CanConnectAsync();
        return Results.Ok(new
        {
            status = dbHealthy ? "healthy" : "unhealthy",
            database = dbHealthy ? "connected" : "disconnected",
            timestamp = DateTime.UtcNow,
            version = "1.0.0"
        });
    }
    catch
    {
        return Results.StatusCode(503);
    }
})
.WithName("ApiStatus")
.WithOpenApi();

// Health checks CRUD
app.MapGet("/api/healthchecks", async (HealthPulseDbContext db, string? status) =>
{
    var query = db.HealthChecks.AsQueryable();
    if (!string.IsNullOrEmpty(status))
        query = query.Where(h => h.Status == status);

    var checks = await query.OrderByDescending(h => h.CheckedAt).ToListAsync();
    return Results.Ok(checks);
})
.WithName("GetHealthChecks")
.WithOpenApi();

app.MapGet("/api/healthchecks/{id:int}", async (int id, HealthPulseDbContext db) =>
{
    var check = await db.HealthChecks.FindAsync(id);
    return check is null ? Results.NotFound() : Results.Ok(check);
})
.WithName("GetHealthCheckById")
.WithOpenApi();

app.MapPost("/api/healthchecks", async (CreateHealthCheckRequest request, HealthPulseDbContext db) =>
{
    var errors = new Dictionary<string, string[]>();

    if (string.IsNullOrWhiteSpace(request.CheckName))
        errors["checkName"] = ["Check name is required."];

    string[] validStatuses = ["healthy", "unhealthy"];
    if (string.IsNullOrWhiteSpace(request.Status) || !validStatuses.Contains(request.Status))
        errors["status"] = [$"Status must be one of: {string.Join(", ", validStatuses)}."];

    if (errors.Count > 0)
        return Results.ValidationProblem(errors);

    var check = new HealthCheck
    {
        CheckName = request.CheckName,
        Status = request.Status,
        CheckedAt = DateTime.UtcNow,
        Message = request.Message
    };

    db.HealthChecks.Add(check);
    await db.SaveChangesAsync();

    return Results.Created($"/api/healthchecks/{check.Id}", check);
})
.WithName("CreateHealthCheck")
.WithOpenApi();

app.MapDelete("/api/healthchecks/{id:int}", async (int id, HealthPulseDbContext db) =>
{
    var check = await db.HealthChecks.FindAsync(id);
    if (check is null) return Results.NotFound();

    db.HealthChecks.Remove(check);
    await db.SaveChangesAsync();

    return Results.NoContent();
})
.WithName("DeleteHealthCheck")
.WithOpenApi();

// Metrics endpoint for Prometheus
app.MapPrometheusScrapingEndpoint("/metrics");

app.Run();

// Required for WebApplicationFactory in tests
public partial class Program { }
