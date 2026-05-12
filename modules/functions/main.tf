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

# 2. App Service Plan (Linux Consumption Y1)
resource "azurerm_service_plan" "functions" {
  name                = "asp-functions-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "Y1"
  tags                = var.tags
}

# 3. Linux Function App
resource "azurerm_linux_function_app" "ingestor" {
  name                       = "func-ingestor-${var.suffix}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  service_plan_id            = azurerm_service_plan.functions.id
  storage_account_name       = azurerm_storage_account.function_app.name
  storage_account_access_key = azurerm_storage_account.function_app.primary_access_key

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

  app_settings = {
    # Runtime
    "FUNCTIONS_WORKER_RUNTIME"       = "python"
    "BUILD_FLAGS"                    = "UseExpressBuild"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"

    # Monitoring — Application Insights
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.appinsights_connection_string

    # Azure OpenAI — endpoints only, auth via Managed Identity
    "AZURE_OPENAI_ENDPOINT"              = var.openai_endpoint
    "AZURE_OPENAI_API_VERSION"           = var.openai_api_version
    "AZURE_OPENAI_EMBEDDING_DEPLOYMENT"  = var.openai_embedding_deployment

    # Azure AI Search — endpoint only, auth via Managed Identity
    "AZURE_SEARCH_ENDPOINT"    = var.search_endpoint
    "AZURE_SEARCH_INDEX_NAME"  = var.search_index_name

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
