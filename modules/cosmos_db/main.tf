# ===========================================================================
# Module: cosmos_db
# Source: app-terraform — Cosmos DB (Serverless) + Database + Container
# ===========================================================================

resource "azurerm_cosmosdb_account" "main" {
  name                = "cosmos-rca-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB" # NoSQL API
  tags                = var.tags

  # Serverless — no provisioned throughput, no hourly minimum cost
  capabilities {
    name = "EnableServerless"
  }

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  # Public access is fine for dev — Private Endpoint in prod
  public_network_access_enabled     = var.public_network_access
  is_virtual_network_filter_enabled = false
}

resource "azurerm_cosmosdb_sql_database" "main" {
  name                = var.database_name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  # No throughput setting on serverless accounts
}

resource "azurerm_cosmosdb_sql_container" "incidents" {
  name                = var.container_name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_sql_database.main.name
  partition_key_paths = [var.partition_key_path]

  indexing_policy {
    indexing_mode = "consistent"

    included_path { path = "/*" }
    excluded_path { path = "/\"_etag\"/?" }
  }
}
