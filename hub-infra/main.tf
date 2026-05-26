resource "azurerm_resource_group" "hub" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.bastion_subnet_cidr]
}

resource "azurerm_subnet" "jumpbox" {
  name                 = "snet-jumpbox"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.jumpbox_subnet_cidr]
}

resource "azurerm_public_ip" "bastion" {
  name                = "pip-bastion-hub"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "hub" {
  name                = "bastion-hub"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = "Basic"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

resource "azurerm_network_interface" "jumpbox" {
  name                = "nic-jumpbox"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.jumpbox.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                = "vm-jumpbox"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  size                = "Standard_B1s"
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.jumpbox.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
