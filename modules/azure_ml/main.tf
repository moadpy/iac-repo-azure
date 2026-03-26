# ─────────────────────────────────────────────────────────────────────────────
# Application Insights for Azure ML experiment tracking
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_application_insights" "ml" {
  name                = "appi-ml-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = var.log_analytics_workspace_id
  application_type    = "web"
  tags                = var.tags
}

# ─────────────────────────────────────────────────────────────────────────────
# Azure Machine Learning Workspace
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_machine_learning_workspace" "main" {
  name                          = "mlw-predictive-maintenance-${var.env}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  application_insights_id       = azurerm_application_insights.ml.id
  key_vault_id                  = var.key_vault_id
  storage_account_id            = var.storage_account_id
  container_registry_id         = var.acr_id
  public_network_access_enabled = false
  tags                          = var.tags

  identity {
    type = "SystemAssigned"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Compute Cluster (auto-scales to 0 when idle)
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_machine_learning_compute_cluster" "training" {
  name                          = "training-cluster"
  location                      = var.location
  vm_priority                   = "Dedicated"
  vm_size                       = var.ml_compute_vm_size
  machine_learning_workspace_id = azurerm_machine_learning_workspace.main.id
  subnet_resource_id            = var.private_subnet_id
  tags                          = var.tags

  scale_settings {
    min_node_count                       = 0
    max_node_count                       = var.ml_compute_max_nodes
    scale_down_nodes_after_idle_duration = "PT2M"
  }

  identity {
    type = "SystemAssigned"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Online Endpoint for real-time inference
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_machine_learning_online_endpoint" "inference" {
  name                          = "ep-predmaint-${var.env}"
  location                      = var.location
  machine_learning_workspace_id = azurerm_machine_learning_workspace.main.id
  auth_mode                     = "Key"
  public_network_access_enabled = false
  tags                          = var.tags

  identity {
    type = "SystemAssigned"
  }
}
