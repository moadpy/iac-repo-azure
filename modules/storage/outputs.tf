output "frontend_storage_account_id" {
  description = "Resource ID of the frontend static website storage account"
  value       = azurerm_storage_account.frontend.id
}

output "frontend_storage_account_name" {
  description = "Name of the frontend static website storage account"
  value       = azurerm_storage_account.frontend.name
}

output "frontend_web_endpoint" {
  description = "Primary web endpoint URL for the static website"
  value       = azurerm_storage_account.frontend.primary_web_endpoint
}

output "ml_storage_account_id" {
  description = "Resource ID of the ML data storage account"
  value       = azurerm_storage_account.ml_data.id
}

output "ml_storage_account_name" {
  description = "Name of the ML data storage account"
  value       = azurerm_storage_account.ml_data.name
}

output "ml_storage_account_primary_key" {
  description = "Primary access key for the ML data storage account"
  value       = azurerm_storage_account.ml_data.primary_access_key
  sensitive   = true
}
