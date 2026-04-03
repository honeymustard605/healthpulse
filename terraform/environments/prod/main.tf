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

  # Production: Uncomment to use remote state in Azure Storage
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "tfstateprod<uniquesuffix>"
  #   container_name       = "tfstate"
  #   key                  = "healthpulse-prod.tfstate"
  # }
}

module "healthpulse_prod" {
  source = "../../"

  project_name            = var.project_name
  environment             = var.environment
  azure_region            = var.azure_region
  kubernetes_version      = var.kubernetes_version
  aks_node_count          = var.aks_node_count
  aks_vm_size             = var.aks_vm_size
  acr_sku                 = var.acr_sku
  db_admin_username       = var.db_admin_username
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "azure_region" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "aks_node_count" {
  type = number
}

variable "aks_vm_size" {
  type = string
}

variable "acr_sku" {
  type = string
}

variable "db_admin_username" {
  type      = string
  sensitive = true
}

output "resource_group_name" {
  value = module.healthpulse_prod.resource_group_name
}
