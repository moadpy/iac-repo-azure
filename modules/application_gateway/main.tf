# ─────────────────────────────────────────────────────────────────────────────
# Public IP for App Gateway
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_public_ip" "appgw" {
  name                = "pip-appgw-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# ─────────────────────────────────────────────────────────────────────────────
# Self-signed certificate for HTTPS listener (stored inline as a placeholder)
# In production, replace with a proper certificate from Key Vault.
# ─────────────────────────────────────────────────────────────────────────────

locals {
  appgw_name                 = "appgw-predictive-maintenance-${var.env}"
  frontend_port_name_http    = "fp-http"
  frontend_ip_config_name    = "feip-${var.env}"
  backend_pool_name_aks      = "bp-aks-${var.env}"
  backend_http_settings_name = "bhs-aks-${var.env}"
  listener_name_http         = "listener-http-${var.env}"
  request_routing_rule_name  = "rrr-api-${var.env}"
  url_path_map_name          = "upm-api-${var.env}"
  url_path_rule_name         = "upr-api-${var.env}"
}

# ─────────────────────────────────────────────────────────────────────────────
# Application Gateway WAF v2
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_application_gateway" "main" {
  name                = local.appgw_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  autoscale_configuration {
    min_capacity = 1
    max_capacity = 3
  }

  gateway_ip_configuration {
    name      = "gwip-${var.env}"
    subnet_id = var.appgw_subnet_id
  }

  # ── Frontend ──────────────────────────────────────────────────────────────

  frontend_ip_configuration {
    name                 = local.frontend_ip_config_name
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  frontend_port {
    name = local.frontend_port_name_http
    port = 80
  }

  # ── Backend Pool ──────────────────────────────────────────────────────────
  # Placeholder IP — updated post-AKS deployment via CI/CD

  backend_address_pool {
    name         = local.backend_pool_name_aks
    ip_addresses = ["10.0.0.100"]
  }

  # ── Backend HTTP Settings ──────────────────────────────────────────────────

  backend_http_settings {
    name                  = local.backend_http_settings_name
    cookie_based_affinity = "Disabled"
    port                  = 8080
    protocol              = "Http"
    request_timeout       = 60
    pick_host_name_from_backend_address = false
  }

  # ── HTTP Listener (port 80) ────────────────────────────────────────────────

  http_listener {
    name                           = local.listener_name_http
    frontend_ip_configuration_name = local.frontend_ip_config_name
    frontend_port_name             = local.frontend_port_name_http
    protocol                       = "Http"
  }

  # ── URL Path Map for /api/* ───────────────────────────────────────────────

  url_path_map {
    name                               = local.url_path_map_name
    default_backend_address_pool_name  = local.backend_pool_name_aks
    default_backend_http_settings_name = local.backend_http_settings_name

    path_rule {
      name                       = local.url_path_rule_name
      paths                      = ["/api/*"]
      backend_address_pool_name  = local.backend_pool_name_aks
      backend_http_settings_name = local.backend_http_settings_name
    }
  }

  # ── Request Routing Rule ─────────────────────────────────────────────────

  request_routing_rule {
    name               = local.request_routing_rule_name
    rule_type          = "PathBasedRouting"
    http_listener_name = local.listener_name_http
    url_path_map_name  = local.url_path_map_name
    priority           = 10
  }

  # ── WAF Configuration ─────────────────────────────────────────────────────

  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"

    request_body_check          = true
    max_request_body_size_kb    = 128
    file_upload_limit_mb        = 100
  }

  lifecycle {
    ignore_changes = [
      # Allow external updates to the backend pool IPs (post-AKS deploy)
      backend_address_pool,
      ssl_certificate,
      tags,
    ]
  }
}
