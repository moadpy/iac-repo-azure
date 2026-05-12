output "storage_account_id" {
  description = "ID of the ML storage account"
  value       = azurerm_storage_account.ml.id
}

output "storage_account_name" {
  description = "Name of the ML storage account"
  value       = azurerm_storage_account.ml.name
}

output "storage_account_connection_string" {
  description = "Primary connection string for the ML storage account"
  value       = azurerm_storage_account.ml.primary_connection_string
  sensitive   = true
}

output "ml_data_container_name" {
  description = "Name of the ML data blob container"
  value       = azurerm_storage_container.ml_data.name
}

output "datasets_container_name" {
  description = "Name of the datasets blob container"
  value       = azurerm_storage_container.datasets.name
}
