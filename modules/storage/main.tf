# ─────────────────────────────────────────────────────────────────────────────
# Frontend Static Website Storage Account
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_storage_account" "frontend" {
  name                     = "stpredmaintfe${var.env}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  allow_nested_items_to_be_public  = true
  public_network_access_enabled    = true
  https_traffic_only_enabled        = true
  min_tls_version                  = "TLS1_2"

  static_website {
    index_document     = "index.html"
    error_404_document = "404.html"
  }

  tags = var.tags
}

# ─────────────────────────────────────────────────────────────────────────────
# ML Data Storage Account
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_storage_account" "ml_data" {
  name                     = "stpredmaint${var.env}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false
  https_traffic_only_enabled       = true
  min_tls_version                 = "TLS1_2"

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }

  tags = var.tags
}

# ─────────────────────────────────────────────────────────────────────────────
# ML Data Container
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_storage_container" "ml_data" {
  name                  = "ml-data"
  storage_account_name  = azurerm_storage_account.ml_data.name
  container_access_type = "private"
}

# ─────────────────────────────────────────────────────────────────────────────
# Storage Management Policy for blob versioning on ML data account
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_storage_management_policy" "ml_data" {
  storage_account_id = azurerm_storage_account.ml_data.id

  rule {
    name    = "ml-data-lifecycle"
    enabled = true

    filters {
      prefix_match = ["ml-data/"]
      blob_types   = ["blockBlob"]
    }

    actions {
      version {
        delete_after_days_since_creation = 90
      }

      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 30
        tier_to_archive_after_days_since_modification_greater_than = 90
        delete_after_days_since_modification_greater_than          = 365
      }
    }
  }
}
