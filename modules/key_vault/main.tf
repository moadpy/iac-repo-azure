# ─────────────────────────────────────────────────────────────────────────────
# Current client config (for bootstrap RBAC assignment)
# ─────────────────────────────────────────────────────────────────────────────

data "azurerm_client_config" "current" {}

# ─────────────────────────────────────────────────────────────────────────────
# Azure Key Vault
# ─────────────────────────────────────────────────────────────────────────────

resource "random_string" "kv_suffix" {
  length  = 3
  special = false
  upper   = false
}

resource "azurerm_key_vault" "main" {
  # Suffix with random string — KV names are globally unique and
  # soft-deleted vaults block reuse across Pluralsight sandbox resets.
  name                          = "kv-predmaint-${var.env}-${random_string.kv_suffix.result}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false
  # Sandbox: must be true so the GitHub Actions runner can write secrets during apply.
  # Private endpoint still provides restricted in-VNet access.
  public_network_access_enabled = true
  # Sandbox: roleAssignments/write is blocked — use vault access policies instead of RBAC.
  enable_rbac_authorization     = false
  tags                          = var.tags
}

# ─────────────────────────────────────────────────────────────────────────────
# Access Policy — grant the deploying SP full secret permissions
# Uses Microsoft.KeyVault/vaults/accessPolicies/write (allowed with Contributor)
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_key_vault_access_policy" "deployer" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
}

# ─────────────────────────────────────────────────────────────────────────────
# Secrets
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_key_vault_secret" "cosmos_primary_key" {
  name         = "cosmos-primary-key"
  value        = var.cosmos_db_primary_key
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_key_vault_access_policy.deployer]
}

resource "azurerm_key_vault_secret" "ml_storage_primary_key" {
  name         = "ml-storage-primary-key"
  value        = var.ml_storage_primary_key
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_key_vault_access_policy.deployer]
}

# Placeholder — populated by the CI/CD pipeline after Azure ML endpoint deployment
resource "azurerm_key_vault_secret" "ml_endpoint_url" {
  name         = "ml-endpoint-url"
  value        = "placeholder"
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_key_vault_access_policy.deployer]

  lifecycle {
    ignore_changes = [value]
  }
}
