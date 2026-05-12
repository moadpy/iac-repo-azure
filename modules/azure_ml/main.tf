# ===========================================================================
# Module: azure_ml
# Source: terraform-ml — Azure Machine Learning Workspace
# ===========================================================================

resource "azurerm_machine_learning_workspace" "main" {
  name                    = var.workspace_name
  resource_group_name     = var.resource_group_name
  location                = var.location
  application_insights_id = var.application_insights_id
  key_vault_id            = var.key_vault_id
  storage_account_id      = var.storage_account_id
  container_registry_id   = var.container_registry_id
  tags                    = var.tags

  identity {
    type = "SystemAssigned"
  }
}

# AcrPull — lets Azure ML pull the training Docker image from the registry
resource "azurerm_role_assignment" "aml_acr_pull" {
  scope                = var.container_registry_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_machine_learning_workspace.main.identity[0].principal_id
}

