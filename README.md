# HealthPulse

A production-deployed REST API built with .NET 8, running on Azure Kubernetes Service with a full CI/CD pipeline and secrets management via Azure Key Vault.

## What This Demonstrates

- Containerization with Docker (multi-stage build, non-root user)
- Kubernetes orchestration on AKS (2 replicas, liveness/readiness probes, resource limits)
- Secrets management via Azure Key Vault (no credentials in code or config)
- CI/CD with GitHub Actions (build → test → push to ACR → deploy to AKS)
- Integration tests with xUnit and WebApplicationFactory
- Input validation and global exception handling
- Auto-applying EF Core migrations on startup

## Architecture

```
GitHub Actions
  └── build & test
  └── push Docker image → Azure Container Registry (ACR)
  └── deploy → AKS

AKS Cluster
  ├── healthpulse-api (2 replicas)
  │     └── reads connection string from Azure Key Vault on startup
  └── postgres (in-cluster, 1 replica)
```

## Tech Stack

| Layer | Technology |
|---|---|
| API | .NET 8 Minimal APIs |
| Database | PostgreSQL + EF Core (Npgsql) |
| Container | Docker |
| Orchestration | Kubernetes (AKS) |
| Registry | Azure Container Registry |
| Secrets | Azure Key Vault |
| CI/CD | GitHub Actions |
| Tests | xUnit, WebApplicationFactory |

## API Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/health` | Health check |
| GET | `/api/healthchecks` | List all health checks |
| GET | `/api/healthchecks/{id}` | Get by ID |
| POST | `/api/healthchecks` | Create a health check |
| DELETE | `/api/healthchecks/{id}` | Delete a health check |

### POST Request Body

```json
{
  "checkName": "database",
  "status": "healthy",
  "message": "optional message"
}
```

Valid status values: `healthy`, `unhealthy`

## Running Locally

### Prerequisites
- Docker
- .NET 8 SDK

### Start with docker-compose

```bash
docker-compose up --build
```

This starts both the API and Postgres. The API will be available at `http://localhost:8080/swagger`.

### Run without Docker

```bash
# Start Postgres (requires Docker)
docker run -e POSTGRES_PASSWORD=localdev -e POSTGRES_DB=healthpulse -p 5432:5432 postgres:15

# Run the API
dotnet run --project src/HealthPulse.Api
```

Swagger UI: `http://localhost:5100/swagger`

### Run Tests

```bash
dotnet test healthpulse.sln
```

## GitHub Actions Setup

The pipeline requires these secrets in your GitHub repo (Settings → Secrets → Actions):

```
AZURE_CLIENT_ID         # Service principal app ID
AZURE_CLIENT_SECRET     # Service principal password
AZURE_TENANT_ID         # Azure AD tenant ID
AZURE_SUBSCRIPTION_ID   # Azure subscription ID
AZURE_REGISTRY_NAME     # ACR name (without .azurecr.io)
AZURE_RESOURCE_GROUP    # Resource group name
AZURE_AKS_CLUSTER       # AKS cluster name
```

## Azure Setup (Manual)

```bash
# Register required providers
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.KeyVault

# Create resources
az group create --name healthpulse-rg --location eastus
az acr create --resource-group healthpulse-rg --name healthpulseacr --sku Basic
az aks create --resource-group healthpulse-rg --name healthpulse-aks \
  --node-count 1 --node-vm-size Standard_B2s --attach-acr healthpulseacr
az keyvault create --name healthpulse-kv --resource-group healthpulse-rg --location eastus

# Store connection string in Key Vault
az keyvault secret set \
  --vault-name healthpulse-kv \
  --name "ConnectionStrings--DefaultConnection" \
  --value "Host=postgres;Port=5432;Database=healthpulse;Username=postgres;Password=localdev"

# Create service principal for GitHub Actions
az ad sp create-for-rbac --name healthpulse-github \
  --role contributor \
  --scopes /subscriptions/<subscription-id>/resourceGroups/healthpulse-rg

# Grant AKS managed identity access to Key Vault
IDENTITY=$(az aks show --resource-group healthpulse-rg --name healthpulse-aks \
  --query identityProfile.kubeletidentity.objectId -o tsv)
az role assignment create --role "Key Vault Secrets User" \
  --assignee $IDENTITY \
  --scope /subscriptions/<subscription-id>/resourceGroups/healthpulse-rg/providers/Microsoft.KeyVault/vaults/healthpulse-kv

# Deploy to AKS
az aks get-credentials --resource-group healthpulse-rg --name healthpulse-aks
kubectl apply -f k8s/
kubectl create secret generic healthpulse-secrets \
  --from-literal=keyVaultUri=https://healthpulse-kv.vault.azure.net/
```

## Live

API: `http://48.194.53.44/health`
