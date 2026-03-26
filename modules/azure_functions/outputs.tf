output "function_app_id" {
  description = "Resource ID of the Function App"
  value       = azurerm_linux_function_app.rag_ingestion.id
}

output "function_app_name" {
  description = "Name of the Function App"
  value       = azurerm_linux_function_app.rag_ingestion.name
}

output "function_app_principal_id" {
  description = "Principal ID of the Function App system-assigned identity"
  value       = azurerm_linux_function_app.rag_ingestion.identity[0].principal_id
}

output "function_app_default_hostname" {
  description = "Default hostname of the Function App"
  value       = azurerm_linux_function_app.rag_ingestion.default_hostname
}
