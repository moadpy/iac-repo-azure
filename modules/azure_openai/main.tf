# ─────────────────────────────────────────────────────────────────────────────
# Azure OpenAI Service
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_cognitive_account" "openai" {
  name                          = "oai-predmaint-${var.env}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  kind                          = "OpenAI"
  sku_name                      = "S0"
  public_network_access_enabled = true
  custom_subdomain_name         = "oai-predmaint-${var.env}"
  tags                          = var.tags
}

# Sandbox: azurerm_cognitive_deployment requires Microsoft.CognitiveServices/accounts/deployments/write
# which is blocked in Pluralsight sandboxes. Deploy models manually via the Azure OpenAI Studio portal.
