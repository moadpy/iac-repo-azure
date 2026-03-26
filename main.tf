terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

locals {
  common_tags = merge(
    {
      environment = var.env
      project     = "predictive-maintenance"
      managed_by  = "terraform"
    },
    var.tags
  )
}

resource "azurerm_resource_group" "main" {
  name     = "rg-predictive-maintenance-${var.env}"
  location = var.location
  tags     = local.common_tags
}

# ─────────────────────────────────────────
# Monitoring (must be first — other modules depend on workspace_id)
# ─────────────────────────────────────────
module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  env                 = var.env
  tags                = local.common_tags
}

# ─────────────────────────────────────────
# ACR (needed by AKS)
# ─────────────────────────────────────────
module "acr" {
  source = "./modules/acr"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  env                 = var.env
  tags                = local.common_tags
}

# ─────────────────────────────────────────
# Storage (ML data + frontend static site)
# ─────────────────────────────────────────
module "storage" {
  source = "./modules/storage"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  env                 = var.env
  tags                = local.common_tags
}

# ─────────────────────────────────────────
# Cosmos DB
# ─────────────────────────────────────────
module "cosmos_db" {
  source = "./modules/cosmos_db"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  env                 = var.env
  tags                = local.common_tags
}

# ─────────────────────────────────────────
# VNet (subnets, NSGs, NAT Gateways)
# ─────────────────────────────────────────
module "vnet" {
  source = "./modules/vnet"

  resource_group_name   = azurerm_resource_group.main.name
  location              = var.location
  env                   = var.env
  vnet_cidr             = var.vnet_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  tags                  = local.common_tags
}

# ─────────────────────────────────────────
# Key Vault (depends on Cosmos + Storage for secrets)
# ─────────────────────────────────────────
module "key_vault" {
  source = "./modules/key_vault"

  resource_group_name   = azurerm_resource_group.main.name
  location              = var.location
  env                   = var.env
  cosmos_db_primary_key = module.cosmos_db.cosmos_db_primary_key
  ml_storage_primary_key = module.storage.ml_storage_account_primary_key
  tags                  = local.common_tags
}

# ─────────────────────────────────────────
# AI Search
# ─────────────────────────────────────────
module "ai_search" {
  source = "./modules/ai_search"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  env                 = var.env
  search_sku          = var.search_sku
  aks_principal_id    = module.aks.aks_identity_principal_id
  tags                = local.common_tags

  depends_on = [module.aks]
}

# ─────────────────────────────────────────
# Azure OpenAI
# ─────────────────────────────────────────
module "azure_openai" {
  source = "./modules/azure_openai"

  resource_group_name              = azurerm_resource_group.main.name
  location                         = var.location
  env                              = var.env
  openai_gpt_model                 = var.openai_gpt_model
  openai_embedding_model           = var.openai_embedding_model
  openai_gpt_capacity_tpu          = var.openai_gpt_capacity_tpu
  openai_embedding_capacity_tpu    = var.openai_embedding_capacity_tpu
  tags                             = local.common_tags
}

# ─────────────────────────────────────────
# Azure ML Workspace
# ─────────────────────────────────────────
module "azure_ml" {
  source = "./modules/azure_ml"

  resource_group_name        = azurerm_resource_group.main.name
  location                   = var.location
  env                        = var.env
  key_vault_id               = module.key_vault.key_vault_id
  storage_account_id         = module.storage.ml_storage_account_id
  acr_id                     = module.acr.acr_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  private_subnet_id          = module.vnet.private_subnet_ids[0]
  ml_compute_vm_size         = var.ml_compute_vm_size
  ml_compute_max_nodes       = var.ml_compute_max_nodes
  tags                       = local.common_tags
}

# ─────────────────────────────────────────
# AKS (depends on VNet, ACR, Monitoring)
# ─────────────────────────────────────────
module "aks" {
  source = "./modules/aks"

  resource_group_name        = azurerm_resource_group.main.name
  location                   = var.location
  env                        = var.env
  private_subnet_ids         = module.vnet.private_subnet_ids
  acr_id                     = module.acr.acr_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  vnet_id                    = module.vnet.vnet_id
  node_vm_size               = var.aks_node_vm_size
  node_count_min             = var.aks_node_count_min
  node_count_max             = var.aks_node_count_max
  tags                       = local.common_tags
}

# ─────────────────────────────────────────
# Application Gateway (WAF v2)
# ─────────────────────────────────────────
module "application_gateway" {
  source = "./modules/application_gateway"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  env                 = var.env
  appgw_subnet_id     = module.vnet.appgw_subnet_id
  tags                = local.common_tags
}

# ─────────────────────────────────────────
# Azure Functions (RAG ingestion)
# ─────────────────────────────────────────
module "azure_functions" {
  source = "./modules/azure_functions"

  resource_group_name        = azurerm_resource_group.main.name
  location                   = var.location
  env                        = var.env
  storage_account_id         = module.storage.ml_storage_account_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                       = local.common_tags
}

# ─────────────────────────────────────────
# Front Door (CDN + WAF)
# ─────────────────────────────────────────
module "front_door" {
  source = "./modules/front_door"

  resource_group_name  = azurerm_resource_group.main.name
  location             = var.location
  env                  = var.env
  frontend_web_endpoint = module.storage.frontend_web_endpoint
  appgw_public_ip      = module.application_gateway.appgw_public_ip_address
  tags                 = local.common_tags
}

# ─────────────────────────────────────────
# Private Endpoints (depends on all PaaS services and VNet)
# ─────────────────────────────────────────
module "private_endpoints" {
  source = "./modules/private_endpoints"

  resource_group_name  = azurerm_resource_group.main.name
  location             = var.location
  env                  = var.env
  vnet_id              = module.vnet.vnet_id
  database_subnet_ids  = module.vnet.database_subnet_ids
  storage_account_id   = module.storage.ml_storage_account_id
  cosmos_db_id         = module.cosmos_db.cosmos_db_id
  ai_search_id         = module.ai_search.ai_search_id
  key_vault_id         = module.key_vault.key_vault_id
  acr_id               = module.acr.acr_id
  openai_id            = module.azure_openai.openai_id
  azureml_id           = module.azure_ml.azure_ml_workspace_id
  log_analytics_id     = module.monitoring.log_analytics_workspace_id
  tags                 = local.common_tags
}
