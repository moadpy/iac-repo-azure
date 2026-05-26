# ===========================================================================
# Module: network
# Purpose: Centralized networking for AKS, NAT Gateway, and AGC
# ===========================================================================

# ---------------------------------------------------------------------------
# Virtual Network
# ---------------------------------------------------------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-aks-${var.suffix}"
  address_space       = [var.vnet_cidr]
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# ---------------------------------------------------------------------------
# Subnets
# ---------------------------------------------------------------------------

# Subnet for AKS Nodes
resource "azurerm_subnet" "aks_nodes" {
  name                 = "snet-aks-nodes"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.aks_subnet_cidr]
}

# Subnet for Application Gateway for Containers (AGC)
# Requires delegation to Microsoft.ServiceNetworking/trafficControllers
resource "azurerm_subnet" "agc" {
  name                 = "snet-agc"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.agc_subnet_cidr]

  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.ServiceNetworking/trafficControllers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# ---------------------------------------------------------------------------
# NAT Gateway (for Egress)
# ---------------------------------------------------------------------------

resource "azurerm_public_ip" "nat" {
  name                = "pip-nat-aks-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway" "nat" {
  name                    = "ng-aks-${var.suffix}"
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 4
  tags                    = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "nat" {
  nat_gateway_id       = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

# Associate NAT Gateway with AKS Subnet
resource "azurerm_subnet_nat_gateway_association" "aks" {
  subnet_id      = azurerm_subnet.aks_nodes.id
  nat_gateway_id = azurerm_nat_gateway.nat.id
}

# ---------------------------------------------------------------------------
# Subnet for Dev VM / Jumpbox
# ---------------------------------------------------------------------------
resource "azurerm_subnet" "dev" {
  name                 = "snet-dev-backend"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.dev_subnet_cidr]
}

# Subnet for Private Endpoints
resource "azurerm_subnet" "pe" {
  name                 = "snet-private-endpoints"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.pe_subnet_cidr]
}

# Subnet for Azure Functions Flex Consumption VNet integration
# Requires delegation to Microsoft.App/environments
resource "azurerm_subnet" "functions" {
  name                 = "snet-functions"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.functions_subnet_cidr]

  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# ---------------------------------------------------------------------------
# Developer SKU Bastion (no public IP / dedicated subnet required)
# ---------------------------------------------------------------------------
resource "azurerm_bastion_host" "spoke_dev" {
  count               = var.deploy_developer_bastion ? 1 : 0
  name                = "bastion-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Developer"
  virtual_network_id  = azurerm_virtual_network.vnet.id
}

# ---------------------------------------------------------------------------
# VNet Peering to Hub (Architectural / Optional)
# ---------------------------------------------------------------------------
data "azurerm_virtual_network" "hub" {
  count               = var.hub_vnet_name != "" ? 1 : 0
  name                = var.hub_vnet_name
  resource_group_name = var.hub_vnet_resource_group_name
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  count                        = var.hub_vnet_name != "" ? 1 : 0
  name                         = "peering-spoke-to-hub"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = data.azurerm_virtual_network.hub[0].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  count                        = var.hub_vnet_name != "" ? 1 : 0
  name                         = "peering-hub-to-${var.suffix}"
  resource_group_name          = var.hub_vnet_resource_group_name
  virtual_network_name         = var.hub_vnet_name
  remote_virtual_network_id    = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

