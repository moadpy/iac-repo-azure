# ===========================================================================
# Module: network — Outputs
# ===========================================================================

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "aks_subnet_id" {
  value = azurerm_subnet.aks_nodes.id
}

output "agc_subnet_id" {
  value = azurerm_subnet.agc.id
}

output "nat_gateway_public_ip" {
  value = azurerm_public_ip.nat.ip_address
}

output "dev_subnet_id" {
  value = azurerm_subnet.dev.id
}

output "pe_subnet_id" {
  value = azurerm_subnet.pe.id
}

output "functions_subnet_id" {
  value = azurerm_subnet.functions.id
}

