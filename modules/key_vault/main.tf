# ===========================================================================
# Module: key_vault
# Source: terraform-ml — Key Vault + access policy
# ===========================================================================

resource "azurerm_key_vault" "main" {
  name                          = "kv-mlops-${var.suffix}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false # keep false for dev so we can clean up easily
  public_network_access_enabled = false
  tags                          = var.tags
}

# Give the Terraform caller (you) full access so the workspace can write secrets
resource "azurerm_key_vault_access_policy" "terraform_caller" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = var.tenant_id
  object_id    = var.caller_object_id

  secret_permissions      = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
  key_permissions         = ["Get", "List", "Create", "Delete", "Purge", "Recover"]
  certificate_permissions = ["Get", "List", "Create", "Delete", "Purge", "Recover"]
}
