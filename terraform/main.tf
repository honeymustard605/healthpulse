terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }

  # Uncomment and configure once Azure storage account is ready
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "tfstate<uniquesuffix>"
  #   container_name       = "tfstate"
  #   key                  = "healthpulse.tfstate"
  # }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.azure_region

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  resource_group_id   = azurerm_resource_group.main.id
  location            = azurerm_resource_group.main.location
  project_name        = var.project_name
  environment         = var.environment
  vnet_cidr           = var.vnet_cidr
  aks_subnet_cidr     = var.aks_subnet_cidr

  tags = azurerm_resource_group.main.tags
}

# Container Registry Module
module "container_registry" {
  source = "./modules/container_registry"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project_name        = var.project_name
  environment         = var.environment
  acr_sku             = var.acr_sku

  tags = azurerm_resource_group.main.tags
}

# AKS Cluster Module
module "aks" {
  source = "./modules/aks"

  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  project_name             = var.project_name
  environment              = var.environment
  kubernetes_version       = var.kubernetes_version
  node_count               = var.aks_node_count
  vm_size                  = var.aks_vm_size
  subnet_id                = module.networking.aks_subnet_id
  container_registry_id    = module.container_registry.acr_id

  tags = azurerm_resource_group.main.tags
}

# Key Vault Module
module "keyvault" {
  source = "./modules/keyvault"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project_name        = var.project_name
  environment         = var.environment
  tenant_id           = data.azurerm_client_config.current.tenant_id

  # Grant AKS kubelet identity access to Key Vault
  akv_access_principals = [module.aks.kubelet_identity_object_id]

  tags = azurerm_resource_group.main.tags
}

# PostgreSQL Database Module
module "postgresql" {
  source = "./modules/postgresql"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project_name        = var.project_name
  environment         = var.environment
  subnet_id           = module.networking.db_subnet_id
  admin_username      = var.db_admin_username
  db_version          = var.postgresql_version

  tags = azurerm_resource_group.main.tags
}

# Store database connection string in Key Vault
resource "azurerm_key_vault_secret" "db_connection_string" {
  name            = "db-connection-string"
  value           = "Server=${module.postgresql.server_fqdn};Port=5432;Database=${module.postgresql.database_name};User Id=${var.db_admin_username};Password=${module.postgresql.admin_password};SslMode=Require;"
  key_vault_id    = module.keyvault.key_vault_id
  depends_on      = [module.keyvault]
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project_name        = var.project_name
  environment         = var.environment

  tags = azurerm_resource_group.main.tags
}

# Current Azure context
data "azurerm_client_config" "current" {}

# Output cluster kubeconfig
resource "null_resource" "configure_kubectl" {
  provisioners {
    local-exec {
      command = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.aks.cluster_name} --overwrite-existing"
    }
  }
  depends_on = [module.aks]
}
