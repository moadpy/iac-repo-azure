# ===========================================================================
# Module: storage
# Source: terraform-ml — Storage Account + Blob Containers
# ===========================================================================

resource "azurerm_storage_account" "ml" {
  name                          = "samlops${var.suffix}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  min_tls_version               = "TLS1_2"
  public_network_access_enabled = true

  static_website {
    index_document     = "index.html"
    error_404_document = "404.html"
  }

  tags = var.tags
}

resource "azurerm_storage_container" "ml_data" {
  name                  = var.storage_container_name
  storage_account_id    = azurerm_storage_account.ml.id
  container_access_type = "private"
}

# Dedicated container for the custom web frontend static assets
resource "azurerm_storage_container" "frontend" {
  name                  = "frontend"
  storage_account_id    = azurerm_storage_account.ml.id
  container_access_type = "private"
}

# Dedicated container for raw training datasets — isolated from ML outputs
# Azure ML training jobs read directly from this container via azureml:// URIs
resource "azurerm_storage_container" "datasets" {
  name                  = "datasets"
  storage_account_id    = azurerm_storage_account.ml.id
  container_access_type = "private"
}

# Container for runbook markdown files 
resource "azurerm_storage_container" "runbooks" {
  name                  = "runbooks"
  storage_account_id    = azurerm_storage_account.ml.id
  container_access_type = "private"
}

# Container for LLM system prompts (chat, investigator, resolver)
resource "azurerm_storage_container" "prompts" {
  name                  = "prompts"
  storage_account_id    = azurerm_storage_account.ml.id
  container_access_type = "private"
}
