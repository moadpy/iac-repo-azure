output "hub_vnet_id" {
  description = "The Resource ID of the Hub VNet"
  value       = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  description = "The name of the Hub VNet"
  value       = azurerm_virtual_network.hub.name
}

output "hub_vnet_resource_group" {
  description = "The Resource Group of the Hub VNet"
  value       = azurerm_resource_group.hub.name
}

output "jumpbox_private_ip" {
  description = "The private IP address of the Jumpbox VM"
  value       = azurerm_linux_virtual_machine.jumpbox.private_ip_address
}
