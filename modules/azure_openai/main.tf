# ─────────────────────────────────────────────────────────────────────────────
# Azure OpenAI Service
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_cognitive_account" "openai" {
  name                          = "oai-predmaint-${var.env}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  kind                          = "OpenAI"
  sku_name                      = "S0"
  public_network_access_enabled = false
  custom_subdomain_name         = "oai-predmaint-${var.env}"
  tags                          = var.tags
}

# ─────────────────────────────────────────────────────────────────────────────
# GPT-4o deployment
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_cognitive_deployment" "gpt" {
  name                 = var.openai_gpt_model
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = var.openai_gpt_model
    version = "2024-11-20"
  }

  scale {
    type     = "GlobalStandard"
    capacity = var.openai_gpt_capacity_tpu
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# text-embedding-3-small deployment
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_cognitive_deployment" "embedding" {
  name                 = var.openai_embedding_model
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = var.openai_embedding_model
    version = "1"
  }

  scale {
    type     = "Standard"
    capacity = var.openai_embedding_capacity_tpu
  }
}
