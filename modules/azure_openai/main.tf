# ===========================================================================
# Module: azure_openai
# Source: app-terraform — Azure OpenAI Account + Model Deployments
# ===========================================================================

resource "azurerm_cognitive_account" "openai" {
  name                          = "oai-rca-${var.suffix}"
  resource_group_name           = var.resource_group_name
  location                      = var.openai_location
  kind                          = "OpenAI"
  sku_name                      = "S0"                    # only available SKU for Azure OpenAI
  custom_subdomain_name         = "oai-rca-${var.suffix}" # Required for Managed Identity / token auth
  public_network_access_enabled = var.public_network_access
  tags                          = var.tags
}

# Chat model deployment (GPT)
resource "azurerm_cognitive_deployment" "chat" {
  name                 = var.chat_model_name
  cognitive_account_id = azurerm_cognitive_account.openai.id
  rai_policy_name      = "Microsoft.DefaultV2"

  model {
    format  = "OpenAI"
    name    = var.chat_model_name
    version = var.chat_model_version
  }

  sku {
    name     = var.chat_sku_name
    capacity = var.chat_sku_capacity
  }
}

# Embedding model deployment (RAG)
resource "azurerm_cognitive_deployment" "embedding" {
  name                 = var.embedding_model_name
  cognitive_account_id = azurerm_cognitive_account.openai.id
  rai_policy_name      = "Microsoft.DefaultV2"

  model {
    format  = "OpenAI"
    name    = var.embedding_model_name
    version = var.embedding_model_version
  }

  sku {
    name     = var.embedding_sku_name
    capacity = var.embedding_sku_capacity
  }
}
