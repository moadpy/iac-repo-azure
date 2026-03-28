# ─────────────────────────────────────────────────────────────────────────────
# Azure AI Search
# Sandbox constraints: only Free or Basic SKU allowed; max one search resource.
# Basic tier: supports private endpoints, up to 500 MB storage / 500 MB vector index.
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_search_service" "main" {
  name                = "srch-predmaint-${var.env}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.search_sku
  replica_count       = 1
  partition_count     = 1

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Sandbox: roleAssignments/write is blocked — assign Search Index Data Contributor to AKS identity manually.
