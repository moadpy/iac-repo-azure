output "vnet_id" {
  description = "The ID of the Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "The name of the Virtual Network"
  value       = azurerm_virtual_network.main.name
}

output "public_subnet_ids" {
  description = "List of IDs for public subnets"
  value       = [for s in azurerm_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "List of IDs for private subnets"
  value       = [for s in azurerm_subnet.private : s.id]
}

output "database_subnet_ids" {
  description = "List of IDs for database subnets"
  value       = [for s in azurerm_subnet.database : s.id]
}

output "appgw_subnet_id" {
  description = "The ID of the Application Gateway dedicated subnet"
  value       = azurerm_subnet.appgw.id
}

output "private_nsg_id" {
  description = "The ID of the private Network Security Group"
  value       = azurerm_network_security_group.private.id
}

output "database_nsg_id" {
  description = "The ID of the database Network Security Group"
  value       = azurerm_network_security_group.database.id
}
