# ===========================================================================
# Module: agc — Outputs
# ===========================================================================

output "alb_id" {
  value = ""
}

output "alb_name" {
  value = ""
}

output "frontend_id" {
  value = ""
}

output "alb_controller_identity_client_id" {
  value = azurerm_user_assigned_identity.alb_controller.client_id
}

output "alb_frontend_fqdn" {
  value = ""
}
