# ===========================================================================
# Module: storage
# Source: terraform-ml — Storage Account + Blob Containers
# ===========================================================================

resource "azurerm_storage_account" "ml" {
  name                     = "samlops${var.suffix}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = var.tags
}

resource "azurerm_storage_container" "ml_data" {
  name                  = var.storage_container_name
  storage_account_name  = azurerm_storage_account.ml.name
  container_access_type = "private"
}

# Dedicated container for raw training datasets — isolated from ML outputs
# Azure ML training jobs read directly from this container via azureml:// URIs
resource "azurerm_storage_container" "datasets" {
  name                  = "datasets"
  storage_account_name  = azurerm_storage_account.ml.name
  container_access_type = "private"
}

# Container for runbook markdown files (trigger for RCA ingestion function)
resource "azurerm_storage_container" "runbooks" {
  name                  = "runbooks"
  storage_account_name  = azurerm_storage_account.ml.name
  container_access_type = "private"
}

# Container for LLM system prompts (chat, investigator, resolver)
resource "azurerm_storage_container" "prompts" {
  name                  = "prompts"
  storage_account_name  = azurerm_storage_account.ml.name
  container_access_type = "private"
}
