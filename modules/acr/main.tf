# ===========================================================================
# Module: acr
# Source: terraform-ml — Azure Container Registry
# ===========================================================================

resource "azurerm_container_registry" "main" {
  name                          = "crmlops${var.suffix}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  admin_enabled                 = true
  public_network_access_enabled = false
  tags                          = var.tags
}
