resource "azurerm_key_vault" "main" {
  name                        = "kv-${var.project_name}-${substr(var.environment, 0, 1)}-${substr(var.tenant_id, 0, 8)}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = var.environment == "prod" ? true : false
  soft_delete_retention_days  = 7

  tags = var.tags
}

resource "azurerm_key_vault_access_policy" "akv_access" {
  for_each = toset(var.akv_access_principals)

  key_vault_id       = azurerm_key_vault.main.id
  tenant_id          = var.tenant_id
  object_id          = each.value

  secret_permissions = [
    "Get",
    "List",
  ]

  key_permissions = [
    "Get",
    "List",
  ]
}
