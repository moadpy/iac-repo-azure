# ===========================================================================
# Module: frontdoor (Azure Front Door)
# Purpose: Route traffic between static frontend and backend via AGC
# ===========================================================================

resource "azurerm_cdn_frontdoor_profile" "fd" {
  name                = "fd-rca-${var.suffix}"
  resource_group_name = var.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"
  tags                = var.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "fd" {
  name                     = "fd-endpoint-${var.suffix}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd.id
}

# -------------------------------------------------------------
# Origin Group - Blob Storage (Frontend)
# -------------------------------------------------------------
resource "azurerm_cdn_frontdoor_origin_group" "blob" {
  name                     = "blob-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd.id
  session_affinity_enabled = false

  load_balancing {
    additional_latency_in_milliseconds = 50
    sample_size                        = 4
    successful_samples_required        = 3
  }

  health_probe {
    path                = "/"
    protocol            = "Https"
    interval_in_seconds = 100
  }
}

resource "azurerm_cdn_frontdoor_origin" "blob" {
  name                           = "blob-origin"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.blob.id
  enabled                        = true
  host_name                      = var.storage_account_primary_web_host
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = var.storage_account_primary_web_host
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true
}

resource "azurerm_cdn_frontdoor_route" "blob" {
  name                          = "blob-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.fd.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.blob.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.blob.id]
  supported_protocols           = ["Http", "Https"]
  patterns_to_match             = ["/*"]
  forwarding_protocol           = "HttpsOnly"
  link_to_default_domain        = true
  https_redirect_enabled        = true
}

# -------------------------------------------------------------
# Origin Group - AGC (Backend)
# -------------------------------------------------------------
resource "azurerm_cdn_frontdoor_origin_group" "agc" {
  # AGC origin group should only be created if AGC FQDN is provided
  count                    = var.agc_fqdn != "" ? 1 : 0
  name                     = "agc-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd.id
  session_affinity_enabled = false

  load_balancing {
    additional_latency_in_milliseconds = 50
    sample_size                        = 4
    successful_samples_required        = 3
  }

  health_probe {
    path                = "/api/health"
    protocol            = "Https"
    interval_in_seconds = 100
  }
}

resource "azurerm_cdn_frontdoor_origin" "agc" {
  count                          = var.agc_fqdn != "" ? 1 : 0
  name                           = "agc-origin"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.agc[0].id
  enabled                        = true
  host_name                      = var.agc_fqdn
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = var.agc_fqdn
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true
}

resource "azurerm_cdn_frontdoor_route" "agc" {
  count                         = var.agc_fqdn != "" ? 1 : 0
  name                          = "agc-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.fd.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.agc[0].id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.agc[0].id]
  supported_protocols           = ["Http", "Https"]
  patterns_to_match             = ["/api/*"]
  forwarding_protocol           = "HttpsOnly"
  link_to_default_domain        = true
  https_redirect_enabled        = true
}
