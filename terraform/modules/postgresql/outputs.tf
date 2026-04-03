output "server_fqdn" {
  value = azurerm_postgresql_flexible_server.main.fqdn
}

output "database_name" {
  value = azurerm_postgresql_flexible_server_database.main.name
}

output "admin_password" {
  value     = random_password.db_password.result
  sensitive = true
}
