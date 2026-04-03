#!/bin/bash

# HealthPulse Setup Script
# This script automates the initial setup of the HealthPulse project

set -e

echo "🚀 HealthPulse Setup"
echo "===================="
echo ""

# Check prerequisites
echo "Checking prerequisites..."

for cmd in az terraform kubectl docker; do
    if ! command -v $cmd &> /dev/null; then
        echo "❌ $cmd is not installed"
        exit 1
    fi
done

echo "✅ All prerequisites installed"
echo ""

# Azure Login
echo "Azure Login"
echo "-----------"
az account show > /dev/null || az login
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
echo "✅ Logged in to Azure subscription: $SUBSCRIPTION_ID"
echo ""

# Terraform Setup
echo "Terraform Initialization"
echo "------------------------"
cd terraform/environments/dev
terraform init
echo "✅ Terraform initialized"
echo ""

# Plan Infrastructure
echo "Planning Infrastructure"
echo "-----------------------"
terraform plan -out=tfplan
echo ""
read -p "Continue with terraform apply? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    terraform apply tfplan
    echo "✅ Infrastructure deployed"
else
    echo "⏭️  Skipped terraform apply"
fi

# Get Terraform outputs
echo ""
echo "Retrieving Terraform outputs..."
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
AKS_CLUSTER=$(terraform output -raw aks_cluster_name)
ACR_NAME=$(terraform output -raw container_registry_login_server | cut -d'.' -f1)
echo "✅ Resource Group: $RESOURCE_GROUP"
echo "✅ AKS Cluster: $AKS_CLUSTER"
echo "✅ ACR: $ACR_NAME"
echo ""

# Configure kubectl
echo "Configuring kubectl"
echo "-------------------"
az aks get-credentials \
  --resource-group "$RESOURCE_GROUP" \
  --name "$AKS_CLUSTER" \
  --overwrite-existing
echo "✅ kubectl configured"
echo ""

# Build and push Docker image
echo "Building and Pushing Docker Image"
echo "----------------------------------"
cd ../../../
docker build -t "$ACR_NAME.azurecr.io/healthpulse-api:latest" .
az acr login --name "$ACR_NAME"
docker push "$ACR_NAME.azurecr.io/healthpulse-api:latest"
echo "✅ Docker image pushed to ACR"
echo ""

# Deploy to Kubernetes
echo "Deploying to Kubernetes"
echo "------------------------"
kubectl apply -f k8s/deployment.yaml
kubectl rollout status deployment/healthpulse-api --timeout=5m
echo "✅ Deployed to AKS"
echo ""

echo "🎉 Setup Complete!"
echo ""
echo "Next steps:"
echo "1. Port-forward to the API: kubectl port-forward svc/healthpulse-api 8080:80 &"
echo "2. Test: curl http://localhost:8080/health"
echo "3. View logs: kubectl logs -f deployment/healthpulse-api"
echo "4. Scale: kubectl scale deployment healthpulse-api --replicas=3"
