locals {
  # Derive the VNet second octet for the AppGateway subnet CIDR (e.g. 10.0.x or 10.1.x)
  vnet_prefix = join(".", slice(split(".", var.vnet_cidr), 0, 2))
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-predictive-maintenance-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_cidr]
  tags                = var.tags
}

# ─── Public Subnets ───────────────────────────────────────────────────────────
resource "azurerm_subnet" "public" {
  count                = 2
  name                 = "snet-public-${var.env}-${count.index + 1}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.public_subnet_cidrs[count.index]]
}

# ─── Private Subnets ──────────────────────────────────────────────────────────
resource "azurerm_subnet" "private" {
  count                = 2
  name                 = "snet-private-${var.env}-${count.index + 1}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.private_subnet_cidrs[count.index]]
}

# ─── Database Subnets ─────────────────────────────────────────────────────────
resource "azurerm_subnet" "database" {
  count                = 2
  name                 = "snet-database-${var.env}-${count.index + 1}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.database_subnet_cidrs[count.index]]

  private_endpoint_network_policies_enabled = false
}

# ─── Application Gateway Subnet ───────────────────────────────────────────────
resource "azurerm_subnet" "appgw" {
  name                 = "snet-appgw-${var.env}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["${local.vnet_prefix}.102.0/24"]
}

# ─── Public IPs for NAT Gateways ──────────────────────────────────────────────
resource "azurerm_public_ip" "nat" {
  count               = 2
  name                = "pip-nat-${var.env}-${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [tostring(count.index + 1)]
  tags                = var.tags
}

# ─── NAT Gateways ─────────────────────────────────────────────────────────────
resource "azurerm_nat_gateway" "main" {
  count               = 2
  name                = "natgw-predictive-maintenance-${var.env}-${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "Standard"
  zones               = [tostring(count.index + 1)]
  tags                = var.tags
}

# ─── NAT Gateway <-> Public IP Associations ───────────────────────────────────
resource "azurerm_nat_gateway_public_ip_association" "main" {
  count                = 2
  nat_gateway_id       = azurerm_nat_gateway.main[count.index].id
  public_ip_address_id = azurerm_public_ip.nat[count.index].id
}

# ─── Associate Private Subnets to NAT Gateways ────────────────────────────────
resource "azurerm_subnet_nat_gateway_association" "private" {
  count          = 2
  subnet_id      = azurerm_subnet.private[count.index].id
  nat_gateway_id = azurerm_nat_gateway.main[count.index].id
}

# ─── Network Security Groups ──────────────────────────────────────────────────

## Public NSG
resource "azurerm_network_security_group" "public" {
  name                = "nsg-public-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "AllowHTTPSInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowOutboundAll"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

## Private NSG
resource "azurerm_network_security_group" "private" {
  name                = "nsg-private-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "AllowAppGatewayInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "${local.vnet_prefix}.102.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowVNetInboundAll"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowVNetOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowInternetOutboundViaNAT"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}

## Database NSG
resource "azurerm_network_security_group" "database" {
  name                = "nsg-database-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "AllowHTTPSFromVNet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyAllOutbound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ─── NSG Associations ─────────────────────────────────────────────────────────
resource "azurerm_subnet_network_security_group_association" "public" {
  count                     = 2
  subnet_id                 = azurerm_subnet.public[count.index].id
  network_security_group_id = azurerm_network_security_group.public.id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  count                     = 2
  subnet_id                 = azurerm_subnet.private[count.index].id
  network_security_group_id = azurerm_network_security_group.private.id
}

resource "azurerm_subnet_network_security_group_association" "database" {
  count                     = 2
  subnet_id                 = azurerm_subnet.database[count.index].id
  network_security_group_id = azurerm_network_security_group.database.id
}
