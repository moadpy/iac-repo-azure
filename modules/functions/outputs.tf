output "function_app_id" {
  description = "The ID of the Function App"
  value       = azurerm_function_app_flex_consumption.ingestor.id
}

output "function_app_principal_id" {
  description = "The Principal ID of the Function App's SystemAssigned Managed Identity"
  value       = azurerm_function_app_flex_consumption.ingestor.identity[0].principal_id
}

output "function_app_name" {
  description = "The name of the Function App"
  value       = azurerm_function_app_flex_consumption.ingestor.name
}

output "function_app_default_hostname" {
  description = "The default hostname of the Function App (e.g. func-ingestor-xxx.azurewebsites.net)"
  value       = azurerm_function_app_flex_consumption.ingestor.default_hostname
}

output "function_app_storage_id" {
  description = "The Resource ID of the storage account used by the Function App"
  value       = azurerm_storage_account.function_app.id
}
