# ===========================================================================
# Module: identity
# Source: terraform-ml + app-terraform — Service Principals + RBAC
#
# Creates two Service Principals:
#   1. Backend SP — used by the FastAPI backend to access OpenAI, Search, Cosmos
#   2. GitHub Actions SP — used by CI/CD to manage ML workspace + storage
#
# All RBAC role assignments are centralized here.
# ===========================================================================

# Dynamic Service Principal creation has been removed.
# Pass existing manually created Service Principal Object IDs as variables.

data "azurerm_client_config" "current" {}

# ---------------------------------------------------------------------------
# RBAC: Backend SP → Azure OpenAI
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "backend_openai" {
  count                = var.backend_sp_object_id != "" ? 1 : 0
  scope                = var.openai_account_id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = var.backend_sp_object_id
}

# ---------------------------------------------------------------------------
# RBAC: Backend SP → Azure AI Search
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "backend_search_data" {
  count                = var.backend_sp_object_id != "" ? 1 : 0
  scope                = var.search_service_id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = var.backend_sp_object_id
}

resource "azurerm_role_assignment" "backend_search_service" {
  count                = var.backend_sp_object_id != "" ? 1 : 0
  scope                = var.search_service_id
  role_definition_name = "Search Service Contributor"
  principal_id         = var.backend_sp_object_id
}

# ---------------------------------------------------------------------------
# RBAC: Backend SP → Cosmos DB (SQL data plane role)
# ---------------------------------------------------------------------------
resource "azurerm_cosmosdb_sql_role_assignment" "backend_cosmos" {
  count               = var.backend_sp_object_id != "" ? 1 : 0
  resource_group_name = var.resource_group_name
  account_name        = var.cosmosdb_account_name
  role_definition_id  = "${var.cosmosdb_account_id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = var.backend_sp_object_id
  scope               = var.cosmosdb_account_id
}

# Also grant the Terraform caller Cosmos access for manual testing
resource "azurerm_cosmosdb_sql_role_assignment" "caller_cosmos" {
  resource_group_name = var.resource_group_name
  account_name        = var.cosmosdb_account_name
  role_definition_id  = "${var.cosmosdb_account_id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = var.caller_object_id
  scope               = var.cosmosdb_account_id
}

# ---------------------------------------------------------------------------
# RBAC: GitHub Actions SP → Resource Group (Contributor)
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "github_contributor" {
  count                = var.github_actions_sp_object_id != "" ? 1 : 0
  scope                = var.resource_group_id
  role_definition_name = "Contributor"
  principal_id         = var.github_actions_sp_object_id
}

# ---------------------------------------------------------------------------
# RBAC: GitHub Actions SP → Storage (Blob Data Contributor)
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "github_storage_blob" {
  count                = var.github_actions_sp_object_id != "" ? 1 : 0
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.github_actions_sp_object_id
}

# ---------------------------------------------------------------------------
# RBAC: Function App Managed Identity → Azure OpenAI (for embeddings)
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "function_openai" {
  scope                = var.openai_account_id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = var.function_app_principal_id
}

# ---------------------------------------------------------------------------
# RBAC: Function App Managed Identity → Azure AI Search (for indexing)
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "function_search_data" {
  scope                = var.search_service_id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = var.function_app_principal_id
}

# ---------------------------------------------------------------------------
# RBAC: Function App Managed Identity → Storage (for runbooks container)
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "function_storage_blob" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.function_app_principal_id
}



# ---------------------------------------------------------------------------
# Key Vault Access: Backend SP → Key Vault (Get, List)
# ---------------------------------------------------------------------------
resource "azurerm_key_vault_access_policy" "backend" {
  count        = var.backend_sp_object_id != "" ? 1 : 0
  key_vault_id = var.key_vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.backend_sp_object_id

  secret_permissions = ["Get", "List"]
}

# ---------------------------------------------------------------------------
# RBAC: Current User (Terraform Caller) → AKS (RBAC Cluster Admin)
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "caller_aks_admin" {
  scope                = var.aks_cluster_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = var.caller_object_id
}

# ---------------------------------------------------------------------------
# RBAC: AKS identity → AGC permissions
# Required for the ALB Controller to manage the Application Load Balancer
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "aks_agc_manager" {
  scope                = var.resource_group_id
  role_definition_name = "AppGw for Containers Configuration Manager"
  principal_id         = var.aks_cluster_identity_principal_id
}

resource "azurerm_role_assignment" "aks_agc_network" {
  scope                = var.agc_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = var.aks_cluster_identity_principal_id
}
