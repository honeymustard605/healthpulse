using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

public class HealthPulseWebApplicationFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        // Use Development so the Key Vault block in Program.cs is skipped
        builder.UseEnvironment("Development");

        builder.ConfigureAppConfiguration((_, config) =>
        {
            config.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["ConnectionStrings:DefaultConnection"] = "Host=localhost;Database=test"
            });
        });

        builder.ConfigureServices(services =>
        {
            // Replace the real PostgreSQL DbContext with an in-memory one
            var descriptor = services.SingleOrDefault(
                d => d.ServiceType == typeof(DbContextOptions<HealthPulseDbContext>));
            if (descriptor is not null)
                services.Remove(descriptor);

            // Capture the name once so all requests in this factory share the same DB
            var dbName = "TestDb_" + Guid.NewGuid();
            services.AddDbContext<HealthPulseDbContext>(options =>
                options.UseInMemoryDatabase(dbName));
        });
    }
}
