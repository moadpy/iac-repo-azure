# ─────────────────────────────────────────────────────────────────────────────
# Azure Front Door Standard Profile
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = "afd-predictive-maintenance-${var.env}"
  resource_group_name = var.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"
  tags                = var.tags
}

# ─────────────────────────────────────────────────────────────────────────────
# Endpoint
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_cdn_frontdoor_endpoint" "main" {
  name                     = "ep-predmaint-${var.env}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  tags                     = var.tags
}

# ─────────────────────────────────────────────────────────────────────────────
# Origin Groups
# ─────────────────────────────────────────────────────────────────────────────

## Static Frontend Origin Group
resource "azurerm_cdn_frontdoor_origin_group" "frontend" {
  name                     = "og-frontend-${var.env}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  session_affinity_enabled = false

  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = 10

  health_probe {
    interval_in_seconds = 60
    path                = "/index.html"
    protocol            = "Https"
    request_type        = "HEAD"
  }

  load_balancing {
    additional_latency_in_milliseconds = 50
    sample_size                        = 4
    successful_samples_required        = 3
  }
}

## API (App Gateway) Origin Group
resource "azurerm_cdn_frontdoor_origin_group" "api" {
  name                     = "og-api-${var.env}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  session_affinity_enabled = false

  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = 10

  health_probe {
    interval_in_seconds = 30
    path                = "/api/health"
    protocol            = "Https"
    request_type        = "HEAD"
  }

  load_balancing {
    additional_latency_in_milliseconds = 50
    sample_size                        = 4
    successful_samples_required        = 3
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Origins
# ─────────────────────────────────────────────────────────────────────────────

## Frontend origin — Blob static website
resource "azurerm_cdn_frontdoor_origin" "frontend" {
  name                          = "origin-frontend-${var.env}"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontend.id

  enabled                        = true
  host_name                      = replace(replace(var.frontend_web_endpoint, "https://", ""), "/", "")
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = replace(replace(var.frontend_web_endpoint, "https://", ""), "/", "")
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true
}

## API origin — App Gateway public IP
resource "azurerm_cdn_frontdoor_origin" "api" {
  name                          = "origin-api-${var.env}"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.api.id

  enabled                        = true
  host_name                      = var.appgw_public_ip
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = var.appgw_public_ip
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = false
}

# ─────────────────────────────────────────────────────────────────────────────
# Routes
# ─────────────────────────────────────────────────────────────────────────────

## Static frontend route (/static/*)
resource "azurerm_cdn_frontdoor_route" "frontend" {
  name                          = "route-frontend-${var.env}"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontend.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.frontend.id]

  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/static/*", "/"]
  supported_protocols    = ["Http", "Https"]

  cdn_frontdoor_custom_domain_ids = []
  link_to_default_domain          = true
}

## API route (/api/*)
resource "azurerm_cdn_frontdoor_route" "api" {
  name                          = "route-api-${var.env}"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.api.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.api.id]

  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/api/*"]
  supported_protocols    = ["Http", "Https"]

  cdn_frontdoor_custom_domain_ids = []
  link_to_default_domain          = true
}

# ─────────────────────────────────────────────────────────────────────────────
# WAF Firewall Policy
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_cdn_frontdoor_firewall_policy" "main" {
  name                              = "wafpredmaint${var.env}"
  resource_group_name               = var.resource_group_name
  sku_name                          = azurerm_cdn_frontdoor_profile.main.sku_name
  enabled                           = true
  mode                              = "Prevention"
  redirect_url                      = null
  custom_block_response_status_code = 403

  managed_rule {
    type    = "DefaultRuleSet"
    version = "1.0"
    action  = "Block"
  }

  managed_rule {
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.0"
    action  = "Block"
  }

  tags = var.tags
}

# ─────────────────────────────────────────────────────────────────────────────
# Security Policy
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_cdn_frontdoor_security_policy" "main" {
  name                     = "sec-policy-${var.env}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.main.id

      association {
        patterns_to_match = ["/*"]

        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.main.id
        }
      }
    }
  }
}
