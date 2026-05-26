output "openai_id" {
  description = "ID of the Azure OpenAI Cognitive Account"
  value       = azurerm_cognitive_account.openai.id
}

output "openai_endpoint" {
  description = "Endpoint URL of the Azure OpenAI service"
  value       = azurerm_cognitive_account.openai.endpoint
}

output "chat_deployment_name" {
  description = "Name of the chat model deployment"
  value       = azurerm_cognitive_deployment.chat.name
}

output "embedding_deployment_name" {
  description = "Name of the embedding model deployment"
  value       = azurerm_cognitive_deployment.embedding.name
}
