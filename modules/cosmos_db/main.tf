# ─────────────────────────────────────────────────────────────────────────────
# Cosmos DB Account (NoSQL, Serverless)
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_cosmosdb_account" "main" {
  name                          = "cosmos-predmaint-${var.env}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  offer_type                    = "Standard"
  kind                          = "GlobalDocumentDB"
  public_network_access_enabled = false

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  capabilities {
    name = "EnableServerless"
  }

  tags = var.tags
}

# ─────────────────────────────────────────────────────────────────────────────
# Database
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_cosmosdb_sql_database" "maintenance" {
  name                = "maintenance"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
}

# ─────────────────────────────────────────────────────────────────────────────
# Container — session history
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_cosmosdb_sql_container" "sessions" {
  name                = "sessions"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_sql_database.maintenance.name
  partition_key_paths = ["/session_id"]

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    excluded_path {
      path = "/\"_etag\"/?"
    }
  }
}
