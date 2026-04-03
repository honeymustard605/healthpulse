FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["src/HealthPulse.Api/HealthPulse.Api.csproj", "HealthPulse.Api/"]
RUN dotnet restore "HealthPulse.Api/HealthPulse.Api.csproj"

COPY ["src/", "."]
RUN dotnet build "HealthPulse.Api/HealthPulse.Api.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "HealthPulse.Api/HealthPulse.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
EXPOSE 8080

RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

USER appuser

COPY --from=publish --chown=appuser:appuser /app/publish .
ENTRYPOINT ["dotnet", "HealthPulse.Api.dll"]
