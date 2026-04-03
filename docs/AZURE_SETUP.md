# Azure Setup Guide for HealthPulse

## Prerequisites Checklist

Before deploying HealthPulse to Azure, ensure you have:

- [ ] Azure Subscription (free trial or MSDN credits work fine)
- [ ] macOS with Homebrew (or Linux/Windows equivalents)
- [ ] Azure CLI installed
- [ ] Terraform >= 1.0
- [ ] Docker Desktop (optional, for local image testing)
- [ ] kubectl (installed with Azure CLI)

## Step 1: Install Azure CLI

```bash
# macOS with Homebrew
brew install azure-cli

# Windows or Linux - see https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
```

## Step 2: Setup Azure Subscription

```bash
# Login to Azure
az login

# If you have multiple subscriptions, list them
az account list --output table

# Set the active subscription (replace with your subscription ID)
az account set --subscription "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Verify you're logged in
az account show
```

Save your Subscription ID and Tenant ID for later:
```bash
az account show --query 'id' -o tsv    # Subscription ID
az account show --query 'tenantId' -o tsv  # Tenant ID
```

## Step 3: Create an Azure Storage Account for Terraform State

Instead of storing Terraform state locally (which becomes problematic in teams), use Azure Storage:

```bash
# Create a new resource group for state management
az group create \
  --name rg-terraform-state \
  --location eastus

# Create a storage account (name must be globally unique, lowercase alphanumeric)
STORAGE_ACCOUNT_NAME="tfstate$(date +%s)"
az storage account create \
  --resource-group rg-terraform-state \
  --name "$STORAGE_ACCOUNT_NAME" \
  --sku Standard_LRS \
  --encryption-services blob

# Create a blob container
az storage container create \
  --name tfstate \
  --account-name "$STORAGE_ACCOUNT_NAME"

# Get storage account key (needed for Terraform backend)
STORAGE_KEY=$(az storage account keys list \
  --resource-group rg-terraform-state \
  --account-name "$STORAGE_ACCOUNT_NAME" \
  --query '[0].value' -o tsv)

echo "Storage Account: $STORAGE_ACCOUNT_NAME"
echo "Storage Key: $STORAGE_KEY"
```

Save these values for the Terraform backend configuration in `terraform/main.tf`.

## Step 4: Configure GitHub Actions (Optional but Recommended)

For CI/CD to work, you need to set up Workload Identity:

```bash
# Create a service principal for GitHub Actions
az ad app create --display-name "healthpulse-github-actions"

# Get the application/client ID
CLIENT_ID=$(az ad app list --display-name "healthpulse-github-actions" --query '[0].appId' -o tsv)

# Create the corresponding service principal
az ad sp create --id "$CLIENT_ID"

# Get the object ID
OBJECT_ID=$(az ad sp show --id "$CLIENT_ID" --query 'id' -o tsv)

# Assign Contributor role at subscription level
SUBSCRIPTION_ID=$(az account show --query 'id' -o tsv)
az role assignment create \
  --assignee "$OBJECT_ID" \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

# Create a GitHub Actions secret file
cat > /tmp/github_secrets.env << EOF
AZURE_CLIENT_ID=$CLIENT_ID
AZURE_TENANT_ID=$(az account show -q --query tenantId -o tsv)
AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
AZURE_REGISTRY_NAME=acrhealthpulsedev
AZURE_RESOURCE_GROUP=rg-healthpulse-dev
AZURE_AKS_CLUSTER=aks-healthpulse-dev
EOF

echo "Save these secrets in GitHub Settings → Secrets and variables → Actions:"
cat /tmp/github_secrets.env
```

## Step 5: Set Resource Quotas (Optional)

Check your subscription's resource quotas:

```bash
# View region capacity
az vm list-usage --location eastus --output table

# AKS requires at least 4 cores and 2.5 GB RAM per node
# Ensure your quota allows for at least 8 cores
```

## Step 6: Deploy Infrastructure

Now you're ready to deploy! From the project root:

```bash
cd terraform/environments/dev

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -out=tfplan

# Review the plan, then apply
terraform apply tfplan
```

This will create:
- Resource Group
- Virtual Network with subnets
- AKS Cluster (2-3 nodes)
- Container Registry
- PostgreSQL Database
- Key Vault
- Log Analytics Workspace
- Network Security Groups

**Expected deployment time: 10-15 minutes**

## Step 7: Verify Deployment

```bash
# Get cluster credentials
az aks get-credentials \
  --resource-group rg-healthpulse-dev \
  --name aks-healthpulse-dev \
  --overwrite-existing

# Verify kubectl can connect
kubectl cluster-info
kubectl get nodes
```

## Cost Estimation

**Dev Environment (default)**
- AKS: $40-50/month
- PostgreSQL: $20-30/month
- Container Registry: $10/month
- Storage + Networking: $10/month
- **Total: ~$80-100/month**

**Cost Optimization**
- Use `terraform destroy` to tear down when not developing
- Use burstable VMs (B-series) instead of general-purpose (D-series)
- Start with 2 nodes instead of 3

## Troubleshooting

### Issue: Quota Exceeded Error
```bash
# Request quota increase in Azure Portal
# Settings → Subscriptions → Usage + quotas → Request quota increase
```

### Issue: Service Principal Already Exists
```bash
# List existing app registrations
az ad app list --output table

# Delete the old one
az ad app delete --id <app-id>
```

### Issue: Terraform State Lock
```bash
# If state gets locked, unlock it
terraform force-unlock <lock-id>

# Or remove local lock file
rm -f .terraform.tfstate.lock.hcl
```

## Next: Deploy the Application

Once infrastructure is ready, continue with [DEVELOPMENT.md](../docs/DEVELOPMENT.md) to:
1. Build the .NET API
2. Push the Docker image to ACR
3. Deploy to Kubernetes
4. Test the API

## Additional Resources

- [Azure Subscription Limits](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits)
- [AKS Pricing](https://azure.microsoft.com/en-us/pricing/details/kubernetes-service/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure CLI Documentation](https://learn.microsoft.com/en-us/cli/azure/)
