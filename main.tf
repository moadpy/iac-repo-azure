# ===========================================================================
# Root main.tf — Modular IaC for RCA Engine / Predictive Maintenance Platform
#
# Consolidates resources from three separate Terraform stacks:
#   - terraform-ml:    ML Workspace, Storage, Key Vault, ACR, Monitoring
#   - app-terraform:   Azure OpenAI, AI Search, Cosmos DB, Identity/RBAC
#   - dev-vm-infra:    Dev VM with networking for backend development
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

locals {
  suffix = random_string.suffix.result
  tags = {
    environment = var.environment
    project     = "predictive-maintenance"
    managed_by  = "terraform"
  }
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
  suffix              = local.suffix
  tags                = local.tags
}

# ─────────────────────────────────────────
# 2. Storage (ML data + blob containers)
# ─────────────────────────────────────────
module "storage" {
  source = "./modules/storage"

  resource_group_name    = azurerm_resource_group.main.name
  location               = var.location
  suffix                 = local.suffix
  storage_container_name = var.storage_container_name
  tags                   = local.tags
}

# ─────────────────────────────────────────
# 3. Key Vault (required by Azure ML)
# ─────────────────────────────────────────
module "key_vault" {
  source = "./modules/key_vault"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  suffix              = local.suffix
  tenant_id           = data.azurerm_client_config.current.tenant_id
  caller_object_id    = data.azurerm_client_config.current.object_id
  tags                = local.tags
}

# ─────────────────────────────────────────
# 4. Container Registry (ACR — stores Docker images for ML envs)
# ─────────────────────────────────────────
module "acr" {
  source = "./modules/acr"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  suffix              = local.suffix
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
  suffix                  = local.suffix
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
  suffix              = local.suffix
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
  suffix              = local.suffix
  tags                = local.tags
}

# ─────────────────────────────────────────
# 9. Azure Functions (Knowledge Base Ingestion)
# ─────────────────────────────────────────
module "functions" {
  source = "./modules/functions"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  suffix              = local.suffix
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

  depends_on = [module.azure_openai, module.ai_search, module.monitoring, module.storage]
}

# ─────────────────────────────────────────
# 10. Identity & RBAC
#    Creates Service Principals + assigns roles to all services
#    Depends on: azure_openai, ai_search, cosmos_db, storage
# ─────────────────────────────────────────
module "identity" {
  source = "./modules/identity"

  resource_group_name       = azurerm_resource_group.main.name
  resource_group_id         = azurerm_resource_group.main.id
  suffix                    = local.suffix
  environment               = var.environment
  caller_object_id          = data.azurerm_client_config.current.object_id
  openai_account_id         = module.azure_openai.openai_id
  search_service_id         = module.ai_search.search_service_id
  cosmosdb_account_id       = module.cosmos_db.cosmosdb_account_id
  cosmosdb_account_name     = module.cosmos_db.cosmosdb_account_name
  storage_account_id        = module.storage.storage_account_id
  function_app_principal_id = module.functions.function_app_principal_id

  depends_on = [module.azure_openai, module.ai_search, module.cosmos_db, module.storage, module.functions]
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
  suffix              = local.suffix
  vm_size             = var.dev_vm_size
  admin_username      = var.dev_vm_admin_username
  ssh_public_key_path = var.dev_vm_ssh_public_key_path
  tags                = local.tags
}

# ─────────────────────────────────────────
# 12. AKS Networking (Dedicated VNet)
# ─────────────────────────────────────────
resource "azurerm_virtual_network" "aks" {
  count               = var.deploy_aks ? 1 : 0
  name                = "vnet-aks-${local.suffix}"
  address_space       = [var.aks_vnet_cidr]
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_subnet" "aks" {
  count                = var.deploy_aks ? 1 : 0
  name                 = "snet-aks-nodes"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.aks[0].name
  address_prefixes     = [var.aks_subnet_cidr]
}

# ─────────────────────────────────────────
# 13. AKS Cluster
#     Depends on: acr (AcrPull), monitoring (Log Analytics)
#     Toggle with deploy_aks = false to skip in dev/low-cost envs
# ─────────────────────────────────────────
module "aks" {
  source = "./modules/aks"
  count  = var.deploy_aks ? 1 : 0

  resource_group_name        = azurerm_resource_group.main.name
  location                   = var.location
  suffix                     = local.suffix
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  acr_id                     = module.acr.acr_id
  vnet_id                    = azurerm_virtual_network.aks[0].id
  subnet_id                  = azurerm_subnet.aks[0].id
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

  depends_on = [module.acr, module.monitoring]
}
