# ===========================================================================
# Module: ai_search
# Source: app-terraform — Azure AI Search Service
# ===========================================================================

resource "azurerm_search_service" "main" {
  name                = "srch-rca-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.search_sku
  tags                = var.tags

  # Free tier does not support replicas/partitions — these are ignored on free
  replica_count   = var.search_sku == "free" ? null : 1
  partition_count = var.search_sku == "free" ? null : 1

  # Disable local auth in prod and use Managed Identity + RBAC instead
  # For dev, keep local auth enabled so API key auth works during testing
  local_authentication_enabled = var.local_auth_enabled
}
