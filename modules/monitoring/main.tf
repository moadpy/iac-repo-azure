# ─────────────────────────────────────────────────────────────────────────────
# Log Analytics Workspace
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-predictive-maintenance-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# ─────────────────────────────────────────────────────────────────────────────
# Application Insights (linked to Log Analytics)
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_application_insights" "main" {
  name                = "appi-predictive-maintenance-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  tags                = var.tags
}
