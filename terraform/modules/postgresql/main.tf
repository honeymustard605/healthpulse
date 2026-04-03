resource "random_password" "db_password" {
  length  = 32
  special = true
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "psql-${var.project_name}-${var.environment}"
  location               = var.location
  resource_group_name    = var.resource_group_name
  administrator_login    = var.admin_username
  administrator_password = random_password.db_password.result
  version                = var.db_version
  sku_name               = var.environment == "prod" ? "B_Standard_B2s" : "B_Burstable_B1ms"
  storage_mb             = 32768
  backup_retention_days  = var.environment == "prod" ? 30 : 7

  delegated_subnet_id = var.subnet_id

  tags = var.tags
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  name            = "healthpulse"
  server_id       = azurerm_postgresql_flexible_server.main.id
  charset         = "UTF8"
  collation       = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_connections" {
  name      = "log_connections"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "on"
}
