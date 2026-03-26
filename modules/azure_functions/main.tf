# ─────────────────────────────────────────────────────────────────────────────
# Storage account for Azure Functions runtime state
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_storage_account" "functions" {
  name                     = "stfnpredmaint${var.env}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = var.tags
}

# ─────────────────────────────────────────────────────────────────────────────
# Consumption (Y1) App Service Plan
# Sandbox: only F1, B1, B2, B3, S1, Y1 SKUs are allowed for App Service Plans.
# Y1 = Consumption plan — serverless, no VNet integration in this tier.
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_service_plan" "functions" {
  name                = "asp-functions-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "Y1"
  tags                = var.tags
}

# ─────────────────────────────────────────────────────────────────────────────
# Function App (RAG ingestion — triggered by Event Grid on blob upload)
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_linux_function_app" "rag_ingestion" {
  name                       = "func-rag-ingestion-${var.env}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  service_plan_id            = azurerm_service_plan.functions.id
  storage_account_name       = azurerm_storage_account.functions.name
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key
  tags                       = var.tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME       = "python"
    FUNCTIONS_EXTENSION_VERSION    = "~4"
    AzureWebJobsStorage            = azurerm_storage_account.functions.primary_connection_string
    WEBSITE_RUN_FROM_PACKAGE       = "1"
    SCM_DO_BUILD_DURING_DEPLOYMENT = "true"
    ML_STORAGE_ACCOUNT_NAME        = ""
    OPENAI_ENDPOINT                = ""
    SEARCH_ENDPOINT                = ""
  }

  lifecycle {
    ignore_changes = [
      app_settings["ML_STORAGE_ACCOUNT_NAME"],
      app_settings["OPENAI_ENDPOINT"],
      app_settings["SEARCH_ENDPOINT"],
    ]
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Diagnostic settings
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_monitor_diagnostic_setting" "functions" {
  name                       = "diag-func-${var.env}"
  target_resource_id         = azurerm_linux_function_app.rag_ingestion.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "FunctionAppLogs"
  }

  metric {
    category = "AllMetrics"
  }
}
