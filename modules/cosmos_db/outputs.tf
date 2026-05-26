output "cosmosdb_account_id" {
  description = "ID of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.main.id
}

output "cosmosdb_account_name" {
  description = "Name of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.main.name
}

output "cosmosdb_endpoint" {
  description = "Endpoint URL of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.main.endpoint
}

output "cosmosdb_database_name" {
  description = "Name of the Cosmos DB SQL database"
  value       = azurerm_cosmosdb_sql_database.main.name
}

output "cosmosdb_container_name" {
  description = "Name of the Cosmos DB SQL container"
  value       = azurerm_cosmosdb_sql_container.incidents.name
}
