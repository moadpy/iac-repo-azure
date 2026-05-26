output "frontdoor_profile_id" {
  description = "The ID of the Front Door Profile."
  value       = azurerm_cdn_frontdoor_profile.fd.id
}

output "frontdoor_endpoint_host_name" {
  description = "The Host Name of the Front Door Endpoint."
  value       = azurerm_cdn_frontdoor_endpoint.fd.host_name
}
