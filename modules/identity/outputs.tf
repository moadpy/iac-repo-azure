# --- Backend SP outputs ---
output "backend_client_id" {
  description = "Client ID of the backend Service Principal"
  value       = var.backend_client_id
}

output "backend_client_secret" {
  description = "Client secret of the backend Service Principal"
  value       = var.backend_client_secret
  sensitive   = true
}

output "backend_sp_object_id" {
  description = "Object ID of the backend Service Principal"
  value       = var.backend_sp_object_id
}

# --- GitHub Actions SP outputs ---
output "github_actions_client_id" {
  description = "Client ID of the GitHub Actions Service Principal"
  value       = var.github_actions_client_id
}

output "github_actions_client_secret" {
  description = "Client secret of the GitHub Actions Service Principal"
  value       = var.github_actions_client_secret
  sensitive   = true
}
