# ===========================================================================
# Module: azure_ml
# Source: terraform-ml — Azure Machine Learning Workspace
# ===========================================================================

resource "azurerm_machine_learning_workspace" "main" {
  name                          = var.workspace_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  application_insights_id       = var.application_insights_id
  key_vault_id                  = var.key_vault_id
  storage_account_id            = var.storage_account_id
  container_registry_id         = var.container_registry_id
  public_network_access_enabled = false
  tags                          = var.tags

  managed_network {
    isolation_mode = "AllowInternetOutbound"
  }

  identity {
    type = "SystemAssigned"
  }
}

# AcrPush — lets Azure ML build and push custom Docker environments to the registry
resource "azurerm_role_assignment" "aml_acr_push" {
  scope                = var.container_registry_id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_machine_learning_workspace.main.identity[0].principal_id
}

