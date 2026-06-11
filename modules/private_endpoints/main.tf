# ===========================================================================
# Module: private_endpoints
# Purpose: Centralized secure private endpoints and private DNS resolution
# ===========================================================================

# ---------------------------------------------------------------------------
# 1. Private DNS Zones
# ---------------------------------------------------------------------------

resource "azurerm_private_dns_zone" "kv" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone" "cosmos" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone" "openai" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone" "search" {
  name                = "privatelink.search.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone" "aml_api" {
  name                = "privatelink.api.azureml.ms"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone" "aml_notebooks" {
  name                = "privatelink.notebooks.azure.net"
  resource_group_name = var.resource_group_name
}

# ---------------------------------------------------------------------------
# 2. Private DNS Zone VNet Links
# ---------------------------------------------------------------------------

resource "azurerm_private_dns_zone_virtual_network_link" "kv" {
  name                  = "lnk-dns-kv-${var.suffix}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.kv.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "lnk-dns-blob-${var.suffix}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                  = "lnk-dns-acr-${var.suffix}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "cosmos" {
  name                  = "lnk-dns-cosmos-${var.suffix}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.cosmos.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "openai" {
  name                  = "lnk-dns-openai-${var.suffix}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.openai.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "search" {
  name                  = "lnk-dns-search-${var.suffix}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.search.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "aml_api" {
  name                  = "lnk-dns-aml-api-${var.suffix}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.aml_api.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "aml_notebooks" {
  name                  = "lnk-dns-aml-notebooks-${var.suffix}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.aml_notebooks.name
  virtual_network_id    = var.vnet_id
}

# ---------------------------------------------------------------------------
# 3. Private Endpoints
# ---------------------------------------------------------------------------

# Key Vault Private Endpoint
resource "azurerm_private_endpoint" "kv" {
  name                = "pe-kv-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-kv-${var.suffix}"
    private_connection_resource_id = var.key_vault_id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "dns-group-kv"
    private_dns_zone_ids = [azurerm_private_dns_zone.kv.id]
  }
}

# Main ML Storage Private Endpoint
resource "azurerm_private_endpoint" "storage_ml" {
  name                = "pe-saml-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-saml-${var.suffix}"
    private_connection_resource_id = var.storage_account_id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "dns-group-storage-ml"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }
}

# Function App Storage Private Endpoint
resource "azurerm_private_endpoint" "storage_functions" {
  name                = "pe-safunc-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-safunc-${var.suffix}"
    private_connection_resource_id = var.function_storage_account_id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "dns-group-storage-functions"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }
}

# Container Registry Private Endpoint
resource "azurerm_private_endpoint" "acr" {
  name                = "pe-acr-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-acr-${var.suffix}"
    private_connection_resource_id = var.acr_id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "dns-group-acr"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]
  }
}

# Cosmos DB Private Endpoint
resource "azurerm_private_endpoint" "cosmos" {
  name                = "pe-cosmos-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-cosmos-${var.suffix}"
    private_connection_resource_id = var.cosmosdb_account_id
    is_manual_connection           = false
    subresource_names              = ["Sql"]
  }

  private_dns_zone_group {
    name                 = "dns-group-cosmos"
    private_dns_zone_ids = [azurerm_private_dns_zone.cosmos.id]
  }
}

# Azure OpenAI Private Endpoint
resource "azurerm_private_endpoint" "openai" {
  name                = "pe-openai-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-openai-${var.suffix}"
    private_connection_resource_id = var.openai_account_id
    is_manual_connection           = false
    subresource_names              = ["account"]
  }

  private_dns_zone_group {
    name                 = "dns-group-openai"
    private_dns_zone_ids = [azurerm_private_dns_zone.openai.id]
  }
}

# Azure AI Search Private Endpoint
resource "azurerm_private_endpoint" "search" {
  name                = "pe-search-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-search-${var.suffix}"
    private_connection_resource_id = var.search_service_id
    is_manual_connection           = false
    subresource_names              = ["searchService"]
  }

  private_dns_zone_group {
    name                 = "dns-group-search"
    private_dns_zone_ids = [azurerm_private_dns_zone.search.id]
  }
}

# Azure ML Workspace Private Endpoint
resource "azurerm_private_endpoint" "aml" {
  name                = "pe-aml-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-aml-${var.suffix}"
    private_connection_resource_id = var.ml_workspace_id
    is_manual_connection           = false
    subresource_names              = ["amlworkspace"]
  }

  # Azure ML requires two separate private DNS zones
  private_dns_zone_group {
    name = "dns-group-aml"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.aml_api.id,
      azurerm_private_dns_zone.aml_notebooks.id
    ]
  }
}
