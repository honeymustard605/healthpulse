variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "healthpulse"
}

variable "environment" {
  description = "Environment (dev, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be 'dev' or 'prod'."
  }
}

variable "azure_region" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "vnet_cidr" {
  description = "CIDR block for virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aks_subnet_cidr" {
  description = "CIDR block for AKS subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "aks_node_count" {
  description = "Number of AKS nodes"
  type        = number
  default     = 2

  validation {
    condition     = var.aks_node_count >= 1 && var.aks_node_count <= 10
    error_message = "Node count must be between 1 and 10."
  }
}

variable "aks_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_B2s"
}

variable "acr_sku" {
  description = "SKU for container registry"
  type        = string
  default     = "Basic"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "ACR SKU must be Basic, Standard, or Premium."
  }
}

variable "db_admin_username" {
  description = "PostgreSQL admin username"
  type        = string
  sensitive   = true
}

variable "postgresql_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15"
}
