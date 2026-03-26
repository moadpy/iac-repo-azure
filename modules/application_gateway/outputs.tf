output "appgw_id" {
  description = "Resource ID of the Application Gateway"
  value       = azurerm_application_gateway.main.id
}

output "appgw_public_ip_address" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.appgw.ip_address
}

output "appgw_public_ip_id" {
  description = "Resource ID of the App Gateway public IP"
  value       = azurerm_public_ip.appgw.id
}

output "backend_address_pool_id" {
  description = "ID of the AKS backend address pool"
  value       = tolist(azurerm_application_gateway.main.backend_address_pool)[0].id
}
