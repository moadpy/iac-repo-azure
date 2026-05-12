output "function_app_id" {
  description = "The ID of the Function App"
  value       = azurerm_linux_function_app.ingestor.id
}

output "function_app_principal_id" {
  description = "The Principal ID of the Function App's SystemAssigned Managed Identity"
  value       = azurerm_linux_function_app.ingestor.identity[0].principal_id
}

output "function_app_name" {
  description = "The name of the Function App"
  value       = azurerm_linux_function_app.ingestor.name
}

output "function_app_default_hostname" {
  description = "The default hostname of the Function App (e.g. func-ingestor-xxx.azurewebsites.net)"
  value       = azurerm_linux_function_app.ingestor.default_hostname
}
