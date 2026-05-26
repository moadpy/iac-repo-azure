output "workspace_id" {
  description = "ID of the Azure ML Workspace"
  value       = azurerm_machine_learning_workspace.main.id
}

output "workspace_name" {
  description = "Name of the Azure ML Workspace"
  value       = azurerm_machine_learning_workspace.main.name
}

output "workspace_identity_principal_id" {
  description = "Principal ID of the workspace's system-assigned managed identity"
  value       = azurerm_machine_learning_workspace.main.identity[0].principal_id
}
