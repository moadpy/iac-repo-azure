# --- Backend SP outputs ---
output "backend_client_id" {
  description = "Client ID of the backend Service Principal"
  value       = azuread_application.backend_app.client_id
}

output "backend_client_secret" {
  description = "Client secret of the backend Service Principal"
  value       = azuread_service_principal_password.backend_sp_password.value
  sensitive   = true
}

output "backend_sp_object_id" {
  description = "Object ID of the backend Service Principal"
  value       = azuread_service_principal.backend_sp.object_id
}

# --- GitHub Actions SP outputs ---
output "github_actions_client_id" {
  description = "Client ID of the GitHub Actions Service Principal"
  value       = azuread_application.github_actions.client_id
}

output "github_actions_client_secret" {
  description = "Client secret of the GitHub Actions Service Principal"
  value       = azuread_service_principal_password.github_actions.value
  sensitive   = true
}
