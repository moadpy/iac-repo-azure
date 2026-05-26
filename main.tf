# ===========================================================================
# Root main.tf — Modular IaC for RCA Engine / Predictive Maintenance Platform
#
#
# Module dependency graph:
#   monitoring  ─┐
#   storage     ─┤
#   key_vault   ─┼──► azure_ml
#   acr         ─┘
#   azure_openai ─┐
#   ai_search    ─┼──► identity (RBAC)
#   cosmos_db    ─┘
#   dev_vm       ──── (independent)
# ===========================================================================


# ---------------------------------------------------------------------------
# Shared data sources and random suffix
# ---------------------------------------------------------------------------
data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}



resource "azurerm_resource_provider_registration" "app" {
  name = "Microsoft.App"
}



# Create the resource group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

# ─────────────────────────────────────────
# 1. Monitoring (Log Analytics + App Insights)
#    Must be first — Azure ML depends on Application Insights
# ─────────────────────────────────────────
module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  suffix              = local.clean_suffix
  tags                = local.tags
}

# ─────────────────────────────────────────
# 2. Storage (ML data + blob containers)
# ─────────────────────────────────────────
module "storage" {
  source = "./modules/storage"

  resource_group_name    = azurerm_resource_group.main.name
  location               = var.location
  suffix                 = local.unique_suffix_alphanumeric
  storage_container_name = var.storage_container_name
  caller_ip              = var.caller_ip
  tags                   = local.tags
}

# ─────────────────────────────────────────
# 3. Key Vault (required by Azure ML)
# ─────────────────────────────────────────
module "key_vault" {
  source = "./modules/key_vault"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  suffix              = local.unique_suffix
  tenant_id           = data.azurerm_client_config.current.tenant_id
  caller_object_id    = data.azurerm_client_config.current.object_id
  tags                = local.tags
}

# ─────────────────────────────────────────
# 4. Container Registry stores env for ml and app registry
# ─────────────────────────────────────────
module "acr" {
  source = "./modules/acr"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  suffix              = local.unique_suffix_alphanumeric
  sku                 = "Premium"
  tags                = local.tags
}

# ─────────────────────────────────────────
# 5. Azure ML Workspace
#    Depends on: monitoring, storage, key_vault, acr
# ─────────────────────────────────────────
module "azure_ml" {
  source = "./modules/azure_ml"

  resource_group_name     = azurerm_resource_group.main.name
  location                = var.location
  workspace_name          = var.ml_workspace_name
  application_insights_id = module.monitoring.application_insights_id
  key_vault_id            = module.key_vault.key_vault_id
  storage_account_id      = module.storage.storage_account_id
  container_registry_id   = module.acr.acr_id
  tags                    = local.tags

  depends_on = [module.key_vault]
}

# ─────────────────────────────────────────
# 6. Azure OpenAI (GPT + Embeddings)
# ─────────────────────────────────────────
module "azure_openai" {
  source = "./modules/azure_openai"

  resource_group_name     = azurerm_resource_group.main.name
  openai_location         = var.openai_location
  suffix                  = local.unique_suffix
  chat_model_name         = var.chat_model_name
  chat_model_version      = var.chat_model_version
  chat_sku_name           = var.chat_sku_name
  chat_sku_capacity       = var.chat_sku_capacity
  embedding_model_name    = var.embedding_model_name
  embedding_model_version = var.embedding_model_version
  embedding_sku_name      = var.embedding_sku_name
  embedding_sku_capacity  = var.embedding_sku_capacity
  tags                    = local.tags
}

# ─────────────────────────────────────────
# 7. Azure AI Search
# ─────────────────────────────────────────
module "ai_search" {
  source = "./modules/ai_search"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  suffix              = local.unique_suffix
  search_sku          = var.search_sku
  tags                = local.tags
}

# ─────────────────────────────────────────
# 8. Cosmos DB (Serverless — incidents store)
# ─────────────────────────────────────────
module "cosmos_db" {
  source = "./modules/cosmos_db"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  suffix              = local.unique_suffix
  tags                = local.tags
}

# ─────────────────────────────────────────
# 9. Azure Functions (Knowledge Base Ingestion)
# ─────────────────────────────────────────
module "functions" {
  source = "./modules/functions"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  suffix              = local.unique_suffix_alphanumeric
  tags                = local.tags

  # Azure OpenAI — endpoints only, auth via Managed Identity
  openai_endpoint             = module.azure_openai.openai_endpoint
  openai_embedding_deployment = module.azure_openai.embedding_deployment_name

  # Azure AI Search — endpoint only, auth via Managed Identity
  search_endpoint            = module.ai_search.search_endpoint
  search_evidence_index_name = var.search_evidence_index_name
  search_runbook_index_name  = var.search_runbook_index_name

  # Monitoring — Application Insights
  appinsights_connection_string = module.monitoring.application_insights_connection_string

  # GitHub integration
  github_webhook_secret = var.github_webhook_secret
  github_token          = var.github_token

  # Blob trigger — ML storage account (where runbooks are uploaded)
  runbooks_storage_connection_string = module.storage.storage_account_connection_string

  # VNet integration subnet
  functions_subnet_id = module.network.functions_subnet_id

  depends_on = [module.azure_openai, module.ai_search, module.monitoring, module.storage, module.network]
}

# ─────────────────────────────────────────
# 10. Identity & RBAC
#    Creates Service Principals + assigns roles to all services
#    Depends on: azure_openai, ai_search, cosmos_db, storage
# ─────────────────────────────────────────
module "identity" {
  source = "./modules/identity"

  resource_group_name                = azurerm_resource_group.main.name
  resource_group_id                  = azurerm_resource_group.main.id
  suffix                             = local.clean_suffix
  environment                        = var.environment
  caller_object_id                   = data.azurerm_client_config.current.object_id
  openai_account_id                  = module.azure_openai.openai_id
  search_service_id                  = module.ai_search.search_service_id
  cosmosdb_account_id                = module.cosmos_db.cosmosdb_account_id
  cosmosdb_account_name              = module.cosmos_db.cosmosdb_account_name
  storage_account_id                 = module.storage.storage_account_id
  function_app_principal_id          = module.functions.function_app_principal_id
  aks_cluster_id                     = module.aks.aks_id
  aks_oidc_issuer_url                = module.aks.oidc_issuer_url
  key_vault_id                       = module.key_vault.key_vault_id
  aks_cluster_identity_principal_id = module.aks.cluster_identity_principal_id
  agc_subnet_id                      = module.network.agc_subnet_id
  deploy_aks                         = true

  depends_on = [module.azure_openai, module.ai_search, module.cosmos_db, module.storage, module.functions, module.aks, module.key_vault]
}

# ─────────────────────────────────────────
# 11. Dev VM (backend development environment)
#     Independent — can be disabled by setting deploy_dev_vm = false
# ─────────────────────────────────────────
module "dev_vm" {
  source = "./modules/dev_vm"
  count  = var.deploy_dev_vm ? 1 : 0

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  suffix              = local.clean_suffix
  subnet_id           = module.network.dev_subnet_id
  vm_size             = var.dev_vm_size
  admin_username      = var.dev_vm_admin_username
  ssh_public_key_path = var.dev_vm_ssh_public_key_path
  tags                = local.tags
}

# ─────────────────────────────────────────
# 12. Networking (VNet, Subnets, NAT Gateway)
# ─────────────────────────────────────────
module "network" {
  source = "./modules/network"

  resource_group_name          = azurerm_resource_group.main.name
  location                     = var.location
  suffix                       = local.clean_suffix
  vnet_cidr                    = var.aks_vnet_cidr
  aks_subnet_cidr              = var.aks_subnet_cidr
  agc_subnet_cidr              = var.aks_agc_subnet_cidr
  dev_subnet_cidr              = var.dev_subnet_cidr
  pe_subnet_cidr               = var.pe_subnet_cidr
  functions_subnet_cidr        = var.functions_subnet_cidr
  deploy_developer_bastion     = var.deploy_developer_bastion
  hub_vnet_name                = var.hub_vnet_name
  hub_vnet_resource_group_name = var.hub_vnet_resource_group_name
  tags                         = local.tags

  depends_on = [azurerm_resource_provider_registration.app]
}

# ─────────────────────────────────────────
# 13. Application Gateway for Containers (AGC)
# ─────────────────────────────────────────
module "agc" {
  source = "./modules/agc"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  suffix              = local.clean_suffix
  agc_subnet_id       = module.network.agc_subnet_id
  aks_oidc_issuer_url = module.aks.oidc_issuer_url
  tags                = local.tags
}

# ─────────────────────────────────────────
# 14. AKS Cluster
#     Depends on: acr (AcrPull), monitoring (Log Analytics)
#     Toggle with deploy_aks = false to skip in dev/low-cost envs
# ─────────────────────────────────────────
module "aks" {
  source = "./modules/aks"

  resource_group_name        = azurerm_resource_group.main.name
  location                   = var.location
  suffix                     = local.unique_suffix
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  acr_id                     = module.acr.acr_id
  vnet_id                    = module.network.vnet_id
  subnet_id                  = module.network.aks_subnet_id
  kubernetes_version         = var.aks_kubernetes_version
  sku_tier                   = var.aks_sku_tier
  system_node_vm_size        = var.aks_system_node_vm_size
  system_node_count          = var.aks_system_node_count
  deploy_user_node_pool      = var.aks_deploy_user_node_pool
  user_node_vm_size          = var.aks_user_node_vm_size
  user_node_count            = var.aks_user_node_count
  service_cidr               = var.aks_service_cidr
  dns_service_ip             = var.aks_dns_service_ip
  tags                       = local.tags

  depends_on = [module.acr, module.monitoring, module.network]
}

# ---------------------------------------------------------------------------
# RBAC: AKS identity → AGC permissions
# Required for the ALB Controller to manage the Application Load Balancer
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "aks_agc_manager" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "AppGw for Containers Configuration Manager"
  principal_id         = module.aks.cluster_identity_principal_id
}

resource "azurerm_role_assignment" "aks_agc_network" {
  scope                = module.network.agc_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = module.aks.cluster_identity_principal_id
}

# ─────────────────────────────────────────
# 15. Azure Front Door
# ─────────────────────────────────────────
module "frontdoor" {
  source = "./modules/frontdoor"
  count  = var.deploy_frontdoor ? 1 : 0

  resource_group_name              = azurerm_resource_group.main.name
  suffix                           = local.unique_suffix
  storage_account_primary_web_host = module.storage.primary_web_host
  agc_fqdn                         = module.agc.alb_frontend_fqdn
  tags                             = local.tags

  depends_on = [module.storage, module.agc]
}

# ─────────────────────────────────────────
# 16. Private Endpoints & DNS Zones
# ─────────────────────────────────────────
module "private_endpoints" {
  source = "./modules/private_endpoints"

  resource_group_name          = azurerm_resource_group.main.name
  location                     = var.location
  suffix                       = local.clean_suffix
  vnet_id                      = module.network.vnet_id
  pe_subnet_id                 = module.network.pe_subnet_id
  key_vault_id                 = module.key_vault.key_vault_id
  storage_account_id           = module.storage.storage_account_id
  function_storage_account_id  = module.functions.function_app_storage_id
  acr_id                       = module.acr.acr_id
  cosmosdb_account_id          = module.cosmos_db.cosmosdb_account_id
  openai_account_id            = module.azure_openai.openai_id
  search_service_id            = module.ai_search.search_service_id
  ml_workspace_id              = module.azure_ml.workspace_id
  tags                         = local.tags

  depends_on = [
    module.network,
    module.key_vault,
    module.storage,
    module.functions,
    module.acr,
    module.cosmos_db,
    module.azure_openai,
    module.ai_search,
    module.azure_ml
  ]
}
