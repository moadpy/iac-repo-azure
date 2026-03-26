output "frontdoor_endpoint_hostname" {
  description = "The hostname of the Azure Front Door endpoint"
  value       = azurerm_cdn_frontdoor_endpoint.main.host_name
}

output "frontdoor_profile_id" {
  description = "The resource ID of the Azure Front Door profile"
  value       = azurerm_cdn_frontdoor_profile.main.id
}
