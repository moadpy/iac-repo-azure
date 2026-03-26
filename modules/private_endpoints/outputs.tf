output "private_dns_zone_ids" {
  description = "Map of service name to Private DNS Zone resource ID"
  value = {
    blob     = azurerm_private_dns_zone.blob.id
    cosmos   = azurerm_private_dns_zone.cosmos.id
    search   = azurerm_private_dns_zone.search.id
    keyvault = azurerm_private_dns_zone.keyvault.id
    acr      = azurerm_private_dns_zone.acr.id
    openai   = azurerm_private_dns_zone.openai.id
    azureml  = azurerm_private_dns_zone.azureml.id
    monitor  = azurerm_private_dns_zone.monitor.id
  }
}
