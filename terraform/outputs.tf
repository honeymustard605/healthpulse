output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  description = "The name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "aks_cluster_id" {
  description = "The ID of the AKS cluster"
  value       = module.aks.cluster_id
}

output "container_registry_login_server" {
  description = "The login server of the container registry"
  value       = module.container_registry.login_server
}

output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = module.keyvault.key_vault_id
}

output "key_vault_uri" {
  description = "The URI of the Key Vault"
  value       = module.keyvault.key_vault_uri
}

output "postgresql_server_fqdn" {
  description = "The FQDN of the PostgreSQL server"
  value       = module.postgresql.server_fqdn
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace"
  value       = module.monitoring.log_analytics_workspace_id
}
