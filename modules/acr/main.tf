# ─────────────────────────────────────────────────────────────────────────────
# Azure Container Registry (Premium — required for Private Endpoint)
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_container_registry" "main" {
  name                          = "acrpredmaint${var.env}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = false
  tags                          = var.tags
}
