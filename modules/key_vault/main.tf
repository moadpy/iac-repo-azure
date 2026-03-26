# ─────────────────────────────────────────────────────────────────────────────
# Current client config (for bootstrap RBAC assignment)
# ─────────────────────────────────────────────────────────────────────────────

data "azurerm_client_config" "current" {}

# ─────────────────────────────────────────────────────────────────────────────
# Azure Key Vault
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_key_vault" "main" {
  name                          = "kv-predmaint-${var.env}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false
  # Sandbox: must be true so the GitHub Actions runner can write secrets during apply.
  # Private endpoint still provides restricted in-VNet access.
  public_network_access_enabled = true
  enable_rbac_authorization     = true
  tags                          = var.tags
}

# ─────────────────────────────────────────────────────────────────────────────
# Grant the CI/CD Service Principal Key Vault Administrator (for bootstrapping)
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ─────────────────────────────────────────────────────────────────────────────
# Secrets
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_key_vault_secret" "cosmos_primary_key" {
  name         = "cosmos-primary-key"
  value        = var.cosmos_db_primary_key
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.kv_admin]
}

resource "azurerm_key_vault_secret" "ml_storage_primary_key" {
  name         = "ml-storage-primary-key"
  value        = var.ml_storage_primary_key
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.kv_admin]
}

# Placeholder — populated by the CI/CD pipeline after Azure ML endpoint deployment
resource "azurerm_key_vault_secret" "ml_endpoint_url" {
  name         = "ml-endpoint-url"
  value        = "placeholder"
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.kv_admin]

  lifecycle {
    ignore_changes = [value]
  }
}
