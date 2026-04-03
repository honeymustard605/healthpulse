# HealthPulse Portfolio Project

Cloud-native health check API deployed on Azure Kubernetes Service (AKS) with infrastructure-as-code, CI/CD, secrets management, and observability.

## 📋 Project Overview

**Resume Line:**  
"Provisioned a containerized health-check API on AKS using Terraform, with GitHub Actions CI/CD, Key Vault secrets integration, and Prometheus/Grafana observability."

**What This Demonstrates:**
- ✅ Infrastructure as Code (Terraform with modular design)
- ✅ Containerization (Docker, .NET 8)
- ✅ Kubernetes orchestration (AKS with HPA, resource limits, security policies)
- ✅ Secrets management (Azure Key Vault with workload identity)
- ✅ CI/CD automation (GitHub Actions with artifact registry push and deployment)
- ✅ Observability (Prometheus metrics, custom alerts, logging)
- ✅ Database provisioning (PostgreSQL with geo-redundancy)
- ✅ Security best practices (RBAC, NSGs, certificate rotation)

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Azure Subscription                     │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐│
│  │ Resource Group: rg-healthpulse-{env}                ││
│  ├─────────────────────────────────────────────────────┤│
│  │  ┌──────────────┐    ┌──────────────┐              ││
│  │  │   AKS        │    │  Key Vault   │              ││
│  │  │ Cluster      │◄──┤ Secrets &    │              ││
│  │  │              │    │ Certificates │              ││
│  │  └──────────────┘    └──────────────┘              ││
│  │    ▲                                                 ││
│  │    │                                                 ││
│  │  Pods  ┌────────────────────────────────────────┐  ││
│  │    │   │  HealthPulse API Deployment (2 replicas) │  ││
│  │    └─►│ - Service (ClusterIP)                   │  ││
│  │        │ - HPA (2-5 replicas)                   │  ││
│  │        │ - Liveness/Readiness probes           │  ││
│  │        │ - 256Mi/512Mi memory requests/limits   │  ││
│  │        └────────────────────────────────────────┘  ││
│  │            │                                        ││
│  │            ▼                                        ││
│  │  ┌──────────────────────┐  ┌──────────────────┐   ││
│  │  │  Azure Container     │  │   PostgreSQL     │   ││
│  │  │  Registry (ACR)      │  │   Flexible Server│   ││
│  │  │                      │  │                  │   ││
│  │  │  healthpulseacr.     │  │  - Database      │   ││
│  │  │  azurecr.io          │  │  - User management│   ││
│  │  └──────────────────────┘  └──────────────────┘   ││
│  │                                                    ││
│  │  ┌──────────────────────────────────────────┐   ││
│  │  │  Networking                               │   ││
│  │  │  - VNet: 10.0.0.0/16                      │   ││
│  │  │  - AKS Subnet: 10.0.1.0/24                │   ││
│  │  │  - DB Subnet: 10.0.2.0/24                 │   ││
│  │  │  - NSG with least-privilege rules         │   ││
│  │  └──────────────────────────────────────────┘   ││
│  │                                                    ││
│  │  ┌──────────────────────────────────────────┐   ││
│  │  │  Monitoring & Observability               │   ││
│  │  │  - Log Analytics Workspace                │   ││
│  │  │  - Prometheus (scrapes /metrics)         │   ││
│  │  │  - Alert Manager                         │   ││
│  │  │  - Grafana (visualizes metrics)          │   ││
│  │  └──────────────────────────────────────────┘   ││
│  └─────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘

CI/CD Pipeline (GitHub Actions):
commit → build → test → push to ACR → deploy to AKS
```

## 📁 Project Structure

```
healthpulse/
├── terraform/                          # Infrastructure as Code
│   ├── main.tf                        # Root module with all resources
│   ├── variables.tf                   # Input variables
│   ├── outputs.tf                     # Output values
│   ├── modules/
│   │   ├── networking/                # VNet, subnets, NSGs
│   │   ├── aks/                       # AKS cluster configuration
│   │   ├── keyvault/                  # Azure Key Vault setup
│   │   ├── container_registry/        # ACR configuration
│   │   ├── postgresql/                # Database provisioning
│   │   └── monitoring/                # Log Analytics, alerts
│   └── environments/
│       ├── dev/
│       │   ├── main.tf                # Dev environment setup
│       │   └── terraform.tfvars       # Dev variables
│       └── prod/
│           ├── main.tf
│           └── terraform.tfvars
├── src/
│   └── HealthPulse.Api/               # .NET 8 Web API
│       ├── HealthPulse.Api.csproj
│       ├── Program.cs                 # Configuration, middleware
│       └── HealthPulseDbContext.cs    # EF Core context & models
├── k8s/                               # Kubernetes manifests
│   └── deployment.yaml                # Deployment, Service, HPA, SA
├── monitoring/                        # Observability configuration
│   ├── prometheus.yml                 # Prometheus scrape config
│   └── alerts.yaml                    # Prometheus alert rules
├── .github/
│   └── workflows/
│       └── build-and-deploy.yml       # GitHub Actions CI/CD
├── Dockerfile                         # Multi-stage container build
└── README.md
```

## 🚀 Quick Start

### Prerequisites
- Azure Subscription (MSDN credits or free trial)
- Azure CLI (`az` command)
- Terraform >= 1.0
- Docker (for building container image locally)
- kubectl (for Kubernetes management)
- Git

### 1. Azure CLI Setup

```bash
# Install Azure CLI if not already installed
brew install azure-cli  # macOS
# or download from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

# Login to Azure
az login

# Set the active subscription (if you have multiple)
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Verify login
az account show
```

### 2. Initialize Terraform

```bash
cd terraform/environments/dev

# Download required providers and modules
terraform init

# Format Terraform code
terraform fmt -recursive ../..

# Validate syntax
terraform validate
```

### 3. Plan and Apply Infrastructure

```bash
# Review what Terraform will create
terraform plan -out=tfplan

# Apply the infrastructure
# WARNING: This will incur Azure costs (typically $3-5/day for dev environment)
terraform apply tfplan

# Save outputs for next steps
terraform output > /tmp/terraform_outputs.json
```

### 4. Configure PostgreSQL Password

```bash
# Generate a strong password
DB_PASSWORD=$(openssl rand -base64 32)

# Apply only the PostgreSQL module with the password
terraform apply \
  -var="db_admin_username=sqladmin" \
  -var="db_admin_password=$DB_PASSWORD" \
  -target=module.postgresql
```

### 5. Push Container Image to ACR

```bash
# Get ACR login credentials
ACR_NAME=$(terraform output -raw container_registry_login_server | cut -d'.' -f1)
az acr login --name $ACR_NAME

# Build and push Docker image
docker build -t healthpulse-api:latest ../..
docker tag healthpulse-api:latest $ACR_NAME.azurecr.io/healthpulse-api:latest
docker push $ACR_NAME.azurecr.io/healthpulse-api:latest
```

### 6. Deploy to AKS

```bash
# Configure kubectl to use your AKS cluster
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
AKS_CLUSTER=$(terraform output -raw aks_cluster_name)

az aks get-credentials \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_CLUSTER \
  --overwrite-existing

# Apply Kubernetes manifests
kubectl apply -f ../../k8s/deployment.yaml

# Verify deployment
kubectl get pods -l app=healthpulse-api
kubectl get svc healthpulse-api
kubectl describe pod <pod-name>
```

### 7. Port-Forward and Test

```bash
# Forward local port 8080 to the service
kubectl port-forward svc/healthpulse-api 8080:80 &

# Test health endpoint
curl http://localhost:8080/health

# Test API status
curl http://localhost:8080/api/status

# View Prometheus metrics
curl http://localhost:8080/metrics
```

## 📊 GitHub Actions CI/CD Setup

The CI/CD pipeline is defined in `.github/workflows/build-and-deploy.yml`. It:

1. **Builds & Tests** on every push to `develop` and PR to `main`
2. **Pushes to ACR** on successful merge to `main`
3. **Deploys to AKS** immediately after push

### Required GitHub Secrets

Add these in Settings → Secrets and variables → Actions:

```
AZURE_CLIENT_ID         # Enterprise Application ID (Workload Identity)
AZURE_TENANT_ID         # Azure AD Tenant ID
AZURE_SUBSCRIPTION_ID   # Subscription ID
AZURE_REGISTRY_NAME     # ACR name (without .azurecr.io)
AZURE_RESOURCE_GROUP    # Resource group name
AZURE_AKS_CLUSTER       # AKS cluster name
```

### Setting Up Workload Identity

```bash
# Create a service principal for GitHub Actions
az ad app create --display-name "healthpulse-github-actions"

# Get the application/client ID
CLIENT_ID=$(az ad app list --display-name "healthpulse-github-actions" --query '[0].appId' -o tsv)

# Create a service principal
az ad sp create --id $CLIENT_ID

# Get the object ID of the service principal
OBJECT_ID=$(az ad sp show --id $CLIENT_ID --query 'id' -o tsv)

# Assign roles to the service principal
az role assignment create --assignee $OBJECT_ID --role "Contributor" --scope "/subscriptions/$(az account show -q --query id -o tsv)"

# Get tenant ID
TENANT_ID=$(az account show -q --query tenantId -o tsv)

echo "Add these to GitHub Secrets:"
echo "AZURE_CLIENT_ID=$CLIENT_ID"
echo "AZURE_TENANT_ID=$TENANT_ID"
```

## 📈 Monitoring & Observability

### Prometheus Metrics

The API exposes metrics on the `/metrics` endpoint:

```bash
curl http://localhost:8080/metrics | grep http_request
```

Key metrics:
- `http_requests_total` — Total HTTP requests (labeled by method, path, status)
- `http_request_duration_seconds` — Request latency histogram
- `.NET runtime metrics` — Memory, GC, threading

### Prometheus Alerts

Alerts are defined in `monitoring/alerts.yaml` and include:

- **HighErrorRate** — Error rate > 5% for 5 minutes
- **HighLatency** — p95 latency > 1 second
- **PodCrashLooping** — Pod restarting frequently
- **DatabaseConnectivityIssue** — Can't connect to PostgreSQL

### Deploy Prometheus & Grafana

```bash
# Add Prometheus Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus Operator
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

# Get Grafana password
kubectl get secret --namespace monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode; echo

# Port-forward to Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 &
# Access at http://localhost:3000 (admin / password from above)
```

## 🔐 Secrets Management

Database connection strings and sensitive config are stored in Azure Key Vault:

```bash
# View secrets (requires RBAC access)
az keyvault secret list --vault-name <kv-name>

# The connection string is injected into the pod via Azure Key Vault Provider for Secrets Store CSI Driver
kubectl get secret db-credentials -o jsonpath='{.data.connection-string}' | base64 -d
```

## 📊 Interview Talking Points

1. **"Walk me through your infrastructure design"**
   - VNet with hub-and-spoke (actually just one hub here, but extensible)
   - AKS in dedicated subnet, database in private subnet
   - NSGs enforce least-privilege inbound/outbound
   - All deployed via Terraform modules (reusable, versioned, testable)

2. **"How do you manage secrets?"**
   - Database passwords generated randomly, stored in Key Vault
   - Pod authenticates to Key Vault via managed identity (no credentials leaked)
   - Connection string injected at runtime into pod environment

3. **"How do you ensure high availability?"**
   - 2 API replicas across availability zones
   - Horizontal Pod Autoscaler scales to 5 replicas under load
   - Liveness probes restart unhealthy containers
   - Readiness probes remove pods from load balancer during startup

4. **"How do you monitor this system?"**
   - Prometheus scrapes /metrics endpoint every 15 seconds
   - Custom alerts for high error rate, latency, database issues
   - Log Analytics captures pod logs for debugging
   - Grafana dashboards visualize metrics and trends

5. **"How would you add another region for disaster recovery?"**
   - Create a second `terraform/environments` folder for the secondary region
   - Use Traffic Manager with health probes for DNS failover
   - PostgreSQL read replica in secondary region, promoted to primary on failover

## 💰 Cost Management

**Estimated Monthly Costs (Dev)**
- AKS cluster (2 B2s nodes): ~$40
- PostgreSQL (burstable): ~$20
- Container Registry: ~$10
- Log Analytics: ~$5-10
- Networking: ~$5
- **Total: ~$80-85/month**

**Cost Reduction Tips**
- Use `terraform destroy` to tear down resources when not actively developing
- Test in smaller Azure regions (East US is cheaper than West US)
- Use B-series VMs (burstable) instead of D-series for dev/test

## 🔧 Cleanup

```bash
# Delete all AWS resources created by Terraform
cd terraform/environments/dev
terraform destroy

# Confirm the deletion
# This will remove AKS, Key Vault, database, container registry, networking
```

## 📚 Next Steps

1. **Add tests** — Create `src/HealthPulse.Api.Tests` with xUnit test cases
2. **Implement endpoints** — Add more health checks (DNS, endpoint probes, etc.)
3. **Extract Terraform modules** — Move reusable code to a separate `terraform-azure-modules` repo
4. **Add Grafana dashboards** — Create visualizations of API metrics
5. **Multi-region failover** — Replicate this setup in a second region with Traffic Manager

## 📖 References

- [Azure Terraform Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [AKS Best Practices](https://docs.microsoft.com/en-us/azure/aks/best-practices)
- [Azure Key Vault Provider for Secrets Store CSI Driver](https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-driver)
- [Prometheus in Kubernetes](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config)
- [ASP.NET Core on Kubernetes](https://docs.microsoft.com/en-us/dotnet/architecture/containerized-lifecycle/)

## 📝 License

This project is for portfolio purposes. MIT License.
