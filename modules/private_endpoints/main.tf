# ─────────────────────────────────────────────────────────────────────────────
# Private DNS Zones
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "cosmos" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "search" {
  name                = "privatelink.search.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "openai" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "azureml" {
  name                = "privatelink.api.azureml.ms"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "monitor" {
  name                = "privatelink.monitor.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# ─────────────────────────────────────────────────────────────────────────────
# Virtual Network Links for Private DNS Zones
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "link-blob-${var.env}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "cosmos" {
  name                  = "link-cosmos-${var.env}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.cosmos.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "search" {
  name                  = "link-search-${var.env}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.search.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "link-keyvault-${var.env}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                  = "link-acr-${var.env}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "openai" {
  name                  = "link-openai-${var.env}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.openai.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "azureml" {
  name                  = "link-azureml-${var.env}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.azureml.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "monitor" {
  name                  = "link-monitor-${var.env}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.monitor.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

# ─────────────────────────────────────────────────────────────────────────────
# Private Endpoints
# ─────────────────────────────────────────────────────────────────────────────

## Blob Storage
resource "azurerm_private_endpoint" "blob" {
  name                = "pe-blob-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.database_subnet_ids[0]
  tags                = var.tags

  private_service_connection {
    name                           = "psc-blob-${var.env}"
    private_connection_resource_id = var.storage_account_id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-group-blob-${var.env}"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.blob]
}

## Cosmos DB
resource "azurerm_private_endpoint" "cosmos" {
  name                = "pe-cosmos-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.database_subnet_ids[0]
  tags                = var.tags

  private_service_connection {
    name                           = "psc-cosmos-${var.env}"
    private_connection_resource_id = var.cosmos_db_id
    subresource_names              = ["Sql"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-group-cosmos-${var.env}"
    private_dns_zone_ids = [azurerm_private_dns_zone.cosmos.id]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.cosmos]
}

## AI Search
resource "azurerm_private_endpoint" "search" {
  name                = "pe-search-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.database_subnet_ids[0]
  tags                = var.tags

  private_service_connection {
    name                           = "psc-search-${var.env}"
    private_connection_resource_id = var.ai_search_id
    subresource_names              = ["searchService"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-group-search-${var.env}"
    private_dns_zone_ids = [azurerm_private_dns_zone.search.id]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.search]
}

## Key Vault
resource "azurerm_private_endpoint" "keyvault" {
  name                = "pe-keyvault-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.database_subnet_ids[0]
  tags                = var.tags

  private_service_connection {
    name                           = "psc-keyvault-${var.env}"
    private_connection_resource_id = var.key_vault_id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-group-keyvault-${var.env}"
    private_dns_zone_ids = [azurerm_private_dns_zone.keyvault.id]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.keyvault]
}

## ACR
resource "azurerm_private_endpoint" "acr" {
  name                = "pe-acr-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.database_subnet_ids[1]
  tags                = var.tags

  private_service_connection {
    name                           = "psc-acr-${var.env}"
    private_connection_resource_id = var.acr_id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-group-acr-${var.env}"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.acr]
}

## Azure OpenAI
resource "azurerm_private_endpoint" "openai" {
  name                = "pe-openai-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.database_subnet_ids[1]
  tags                = var.tags

  private_service_connection {
    name                           = "psc-openai-${var.env}"
    private_connection_resource_id = var.openai_id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-group-openai-${var.env}"
    private_dns_zone_ids = [azurerm_private_dns_zone.openai.id]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.openai]
}

## Azure ML Workspace
resource "azurerm_private_endpoint" "azureml" {
  name                = "pe-azureml-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.database_subnet_ids[1]
  tags                = var.tags

  private_service_connection {
    name                           = "psc-azureml-${var.env}"
    private_connection_resource_id = var.azureml_id
    subresource_names              = ["amlworkspace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-group-azureml-${var.env}"
    private_dns_zone_ids = [azurerm_private_dns_zone.azureml.id]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.azureml]
}

## Log Analytics (Monitor)
resource "azurerm_private_endpoint" "monitor" {
  name                = "pe-monitor-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.database_subnet_ids[1]
  tags                = var.tags

  private_service_connection {
    name                           = "psc-monitor-${var.env}"
    private_connection_resource_id = var.log_analytics_id
    subresource_names              = ["azuremonitor"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-group-monitor-${var.env}"
    private_dns_zone_ids = [azurerm_private_dns_zone.monitor.id]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.monitor]
}
