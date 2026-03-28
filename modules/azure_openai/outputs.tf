output "openai_id" {
  description = "Resource ID of the Azure OpenAI account"
  value       = azurerm_cognitive_account.openai.id
}

output "openai_endpoint" {
  description = "Endpoint URL of the Azure OpenAI service"
  value       = azurerm_cognitive_account.openai.endpoint
}

output "openai_name" {
  description = "Name of the Azure OpenAI account"
  value       = azurerm_cognitive_account.openai.name
}
