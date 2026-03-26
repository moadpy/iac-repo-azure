output "ai_search_id" {
  description = "Resource ID of the AI Search service"
  value       = azurerm_search_service.main.id
}

output "ai_search_name" {
  description = "Name of the AI Search service"
  value       = azurerm_search_service.main.name
}

output "ai_search_endpoint" {
  description = "Endpoint URL of the AI Search service"
  value       = "https://${azurerm_search_service.main.name}.search.windows.net"
}
