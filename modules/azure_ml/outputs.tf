output "azure_ml_workspace_id" {
  description = "Resource ID of the Azure ML Workspace"
  value       = azurerm_machine_learning_workspace.main.id
}

output "azure_ml_workspace_name" {
  description = "Name of the Azure ML Workspace"
  value       = azurerm_machine_learning_workspace.main.name
}

output "azure_ml_compute_cluster_id" {
  description = "Resource ID of the training compute cluster"
  value       = azurerm_machine_learning_compute_cluster.training.id
}

output "azure_ml_principal_id" {
  description = "Principal ID of the Azure ML Workspace system-assigned identity"
  value       = azurerm_machine_learning_workspace.main.identity[0].principal_id
}
