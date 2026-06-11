# ===========================================================================
# Module: functions
# Purpose: Serverless compute for ingesting Runbooks and GitHub PRs
#
# Authentication: System-Assigned Managed Identity (no API keys)
#   - Azure OpenAI:  Cognitive Services OpenAI User  (assigned in identity module)
#   - Azure AI Search: Search Index Data Contributor  (assigned in identity module)
#   - Azure Blob Storage: Storage Blob Data Contributor (assigned in identity module)
# ===========================================================================

# 1. Dedicated Storage Account for the Function App (AzureWebJobsStorage)
resource "azurerm_storage_account" "function_app" {
  name                     = "safunc${var.suffix}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

# Storage container to host the function app deployment packages
resource "azurerm_storage_container" "function_app_package" {
  name                  = "app-package"
  storage_account_id    = azurerm_storage_account.function_app.id
  container_access_type = "private"
}

# 2. App Service Plan (Flex Consumption FC1)
resource "azurerm_service_plan" "functions" {
  name                = "asp-functions-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "FC1"
  tags                = var.tags
}

# 3. Linux Function App (Flex Consumption)
resource "azurerm_function_app_flex_consumption" "ingestor" {
  name                = "func-ingestor-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.functions.id

  # Runtime settings
  runtime_name    = "python"
  runtime_version = "3.11"

  # Storage settings
  storage_container_type      = "blobContainer"
  storage_container_endpoint  = "${azurerm_storage_account.function_app.primary_blob_endpoint}${azurerm_storage_container.function_app_package.name}"
  storage_authentication_type = "StorageAccountConnectionString"
  storage_access_key          = azurerm_storage_account.function_app.primary_access_key

  # VNet integration subnet
  virtual_network_subnet_id = var.functions_subnet_id

  site_config {
    application_insights_connection_string = var.appinsights_connection_string
  }

  app_settings = {
    # Runtime
    "BUILD_FLAGS" = "UseExpressBuild"

    # Azure OpenAI — endpoints only, auth via Managed Identity
    "AZURE_OPENAI_ENDPOINT"             = var.openai_endpoint
    "AZURE_OPENAI_API_VERSION"          = var.openai_api_version
    "AZURE_OPENAI_EMBEDDING_DEPLOYMENT" = var.openai_embedding_deployment

    # Azure AI Search — endpoint only, auth via Managed Identity
    "AZURE_SEARCH_ENDPOINT"            = var.search_endpoint
    "AZURE_SEARCH_EVIDENCE_INDEX_NAME" = var.search_evidence_index_name
    "AZURE_SEARCH_RUNBOOK_INDEX_NAME"  = var.search_runbook_index_name

    # GitHub (external service — PAT required)
    "GITHUB_WEBHOOK_SECRET" = var.github_webhook_secret
    "GITHUB_TOKEN"          = var.github_token

    # Blob trigger connection for runbooks (ML storage account, not the Function App's storage)
    "RunbooksStorageConnection" = var.runbooks_storage_connection_string
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}
