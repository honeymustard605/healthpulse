# HealthPulse Development Guide

## Setting Up Your Local Development Environment

### Prerequisites
- .NET 8 SDK
- PostgreSQL 15+ (local or via Docker)
- Docker Desktop
- Visual Studio Code or Visual Studio

### 1. Local Database Setup

```bash
# Using Docker
docker run --name healthpulse-postgres \
  -e POSTGRES_PASSWORD=localdev \
  -p 5432:5432 \
  -d postgres:15

# Create database
docker exec healthpulse-postgres \
  psql -U postgres -c "CREATE DATABASE healthpulse;"
```

### 2. Environment Configuration

Create `appsettings.Development.json`:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Port=5432;Database=healthpulse;User Id=postgres;Password=localdev;"
  }
}
```

### 3. Run the API Locally

```bash
cd src/HealthPulse.Api
dotnet run
```

API will be available at `http://localhost:5000` (or `https://localhost:5001`).

### 4. Database Migrations

```bash
# Install EF Core tools
dotnet tool install --global dotnet-ef

# Create a migration
dotnet ef migrations add InitialCreate

# Apply migrations
dotnet ef database update
```

## Project Architecture

### API Endpoints

- `GET /health` — Simple health check (always returns 200)
- `GET /api/status` — Detailed status (checks database connectivity)
- `GET /metrics` — Prometheus metrics (OpenTelemetry format)
- `GET /swagger` — Swagger UI (OpenAPI documentation)

### Dependency Injection

The API uses ASP.NET Core's built-in DI container. Key registrations in `Program.cs`:

- `DbContext` — Entity Framework Core for PostgreSQL
- `OpenTelemetry` — Metrics and tracing
- Service and repository layers (add as needed)

### Database Schema

The `HealthPulseDbContext` defines the following tables:

**HealthChecks**
- Id (int, primary key)
- CheckName (string, indexed)
- Status (string: "healthy", "unhealthy")
- CheckedAt (datetime)
- Message (string, nullable)

## Development Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feature/add-endpoint-monitoring
```

### 2. Make Changes

```bash
# Edit code in src/HealthPulse.Api/
# Update models, endpoints, database context, etc.

# Build and test locally
dotnet build src/HealthPulse.Api/
dotnet run --project src/HealthPulse.Api/
```

### 3. Commit and Push

```bash
git add .
git commit -m "Add endpoint monitoring"
git push origin feature/add-endpoint-monitoring
```

### 4. GitHub Actions

- Push to `develop` or open PR to `main` → **Build & Test**
- Merge to `main` → **Build → Push to ACR → Deploy to AKS**

## Adding New Endpoints

Example: Add a `/api/checks` endpoint to list all health checks:

```csharp
// In Program.cs, after other route handlers:

app.MapGet("/api/checks", async (HealthPulseDbContext db) =>
{
    var checks = await db.HealthChecks
        .OrderByDescending(x => x.CheckedAt)
        .Take(100)
        .ToListAsync();
    return Results.Ok(checks);
})
.WithName("GetHealthChecks")
.WithOpenApi();

app.MapPost("/api/checks", async (HealthPulseDbContext db, HealthCheck check) =>
{
    check.CheckedAt = DateTime.UtcNow;
    db.HealthChecks.Add(check);
    await db.SaveChangesAsync();
    return Results.CreatedAtRoute(
        routeName: "GetHealthCheck",
        routeValues: new { id = check.Id },
        value: check);
})
.WithName("CreateHealthCheck")
.WithOpenApi();
```

## Pushing Container Images

```bash
# Build Docker image
docker build -t healthpulse-api:v1.0.0 .

# Tag for ACR
docker tag healthpulse-api:v1.0.0 <acr-name>.azurecr.io/healthpulse-api:v1.0.0

# Push to ACR
az acr login --name <acr-name>
docker push <acr-name>.azurecr.io/healthpulse-api:v1.0.0
```

## Troubleshooting

### Issue: "Can't connect to PostgreSQL"
- Ensure container is running: `docker ps | grep postgres`
- Check connection string in `appsettings.Development.json`
- Test connection: `psql -h localhost -U postgres -d healthpulse`

### Issue: Migrations fail
- Check for pending migrations: `dotnet ef migrations list`
- Revert last migration if needed: `dotnet ef migrations remove`

### Issue: Port already in use
- Find process using port 5000: `lsof -i :5000`
- Kill it: `kill -9 <PID>`
- Or use a different port: `dotnet run -- --urls="http://localhost:5555"`

## Performance Tuning

### Database Query Optimization
- Use `.AsNoTracking()` for read-only queries
- Add indexes on frequently filtered columns
- Monitor slow queries in PostgreSQL logs

### Memory Usage
- Container has 256Mi request / 512Mi limit
- Monitor with `kubectl top pod <pod-name>`
- Use memory profilers if approaching limits

### API Latency
- Cache frequently accessed data (e.g., configuration)
- Use async/await throughout
- Set appropriate connection pool sizes

## Testing (Optional)

Create `src/HealthPulse.Api.Tests/HealthPulseApiTests.cs`:

```csharp
using Xunit;

public class HealthPulseApiTests
{
    [Fact]
    public async Task HealthEndpoint_Returns200OK()
    {
        // Arrange
        var client = new HttpClient { BaseAddress = new Uri("http://localhost:5000") };
        
        // Act
        var response = await client.GetAsync("/health");
        
        // Assert
        Assert.Equal(System.Net.HttpStatusCode.OK, response.StatusCode);
    }
}
```

Run: `dotnet test`
