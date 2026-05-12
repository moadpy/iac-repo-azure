output "acr_id" {
  description = "ID of the Container Registry"
  value       = azurerm_container_registry.main.id
}

output "acr_login_server" {
  description = "Login server URL of the Container Registry"
  value       = azurerm_container_registry.main.login_server
}

output "acr_name" {
  description = "Name of the Container Registry"
  value       = azurerm_container_registry.main.name
}
