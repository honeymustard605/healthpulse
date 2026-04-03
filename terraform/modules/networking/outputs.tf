output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet"
  value       = azurerm_subnet.aks.id
}

output "db_subnet_id" {
  description = "ID of the database subnet"
  value       = azurerm_subnet.database.id
}
