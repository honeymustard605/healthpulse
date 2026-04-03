using System.Net;
using System.Net.Http.Json;
using Xunit;

public class HealthChecksApiTests : IClassFixture<HealthPulseWebApplicationFactory>
{
    private readonly HttpClient _client;

    public HealthChecksApiTests(HealthPulseWebApplicationFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task HealthEndpoint_Returns200()
    {
        var response = await _client.GetAsync("/health");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task GetHealthChecks_ReturnsOkWithList()
    {
        var response = await _client.GetAsync("/api/healthchecks");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task CreateHealthCheck_Returns201WithLocation()
    {
        var request = new { checkName = "database", status = "healthy", message = "All good" };

        var response = await _client.PostAsJsonAsync("/api/healthchecks", request);

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        Assert.NotNull(response.Headers.Location);
    }

    [Fact]
    public async Task GetHealthCheckById_AfterCreate_ReturnsRecord()
    {
        var request = new { checkName = "cache", status = "healthy", message = (string?)null };
        var created = await _client.PostAsJsonAsync("/api/healthchecks", request);
        var location = created.Headers.Location!.ToString();

        var response = await _client.GetAsync(location);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task GetHealthCheckById_NonExistent_Returns404()
    {
        var response = await _client.GetAsync("/api/healthchecks/99999");
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task DeleteHealthCheck_Returns204()
    {
        var request = new { checkName = "disk", status = "unhealthy", message = "Low space" };
        var created = await _client.PostAsJsonAsync("/api/healthchecks", request);
        var location = created.Headers.Location!.ToString();

        var response = await _client.DeleteAsync(location);

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
    }
}
