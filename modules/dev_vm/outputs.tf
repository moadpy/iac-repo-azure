output "vm_public_ip" {
  description = "Public IP address of the Dev VM"
  value       = azurerm_public_ip.dev.ip_address
}

output "vm_name" {
  description = "Name of the Dev VM"
  value       = azurerm_linux_virtual_machine.dev.name
}

output "ssh_command" {
  description = "SSH command to connect to the Dev VM"
  value       = "ssh -i ~/.ssh/id_rsa ${var.admin_username}@${azurerm_public_ip.dev.ip_address}"
}

output "vnet_id" {
  description = "ID of the dev VNet"
  value       = azurerm_virtual_network.dev.id
}

output "subnet_id" {
  description = "ID of the dev subnet"
  value       = azurerm_subnet.dev.id
}
