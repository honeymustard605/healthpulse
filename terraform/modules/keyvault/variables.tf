variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "akv_access_principals" {
  type        = list(string)
  description = "List of object IDs that need access to Key Vault"
  default     = []
}

variable "tags" {
  type = map(string)
}
