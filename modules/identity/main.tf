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

# ---------------------------------------------------------------------------
# Backend Application SP (from app-terraform)
# Used by the FastAPI RCA engine to access Azure services
# ---------------------------------------------------------------------------
resource "azuread_application" "backend_app" {
  display_name = "rca-backend-app-${var.suffix}"
  owners       = [var.caller_object_id]
}

resource "azuread_service_principal" "backend_sp" {
  client_id                    = azuread_application.backend_app.client_id
  app_role_assignment_required = false
  owners                       = [var.caller_object_id]
}

resource "azuread_service_principal_password" "backend_sp_password" {
  service_principal_id = azuread_service_principal.backend_sp.object_id
}

# ---------------------------------------------------------------------------
# GitHub Actions SP (from terraform-ml)
# Used by CI/CD pipelines for ML training and blob sync
# ---------------------------------------------------------------------------
resource "azuread_application" "github_actions" {
  display_name = "sp-mlops-github-actions-${var.environment}"
}

resource "azuread_service_principal" "github_actions" {
  client_id = azuread_application.github_actions.client_id
}

resource "azuread_service_principal_password" "github_actions" {
  service_principal_id = azuread_service_principal.github_actions.id
  end_date_relative    = "8760h" # 1 year
}

# ---------------------------------------------------------------------------
# RBAC: Backend SP → Azure OpenAI
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "backend_openai" {
  scope                = var.openai_account_id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azuread_service_principal.backend_sp.object_id
}

# ---------------------------------------------------------------------------
# RBAC: Backend SP → Azure AI Search
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "backend_search_data" {
  scope                = var.search_service_id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = azuread_service_principal.backend_sp.object_id
}

resource "azurerm_role_assignment" "backend_search_service" {
  scope                = var.search_service_id
  role_definition_name = "Search Service Contributor"
  principal_id         = azuread_service_principal.backend_sp.object_id
}

# ---------------------------------------------------------------------------
# RBAC: Backend SP → Cosmos DB (SQL data plane role)
# ---------------------------------------------------------------------------
resource "azurerm_cosmosdb_sql_role_assignment" "backend_cosmos" {
  resource_group_name = var.resource_group_name
  account_name        = var.cosmosdb_account_name
  role_definition_id  = "${var.cosmosdb_account_id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = azuread_service_principal.backend_sp.object_id
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
  scope                = var.resource_group_id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}

# ---------------------------------------------------------------------------
# RBAC: GitHub Actions SP → Storage (Blob Data Contributor)
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "github_storage_blob" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
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
# Workload Identity: Federated Credential for Backend Pods
# ---------------------------------------------------------------------------
resource "azuread_application_federated_identity_credential" "backend" {
  application_id = azuread_application.backend_app.id
  display_name   = "rca-backend-federated-identity"
  description    = "Trust the rca-backend service account in rca-dev namespace"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = var.aks_oidc_issuer_url
  subject        = "system:serviceaccount:rca-dev:rca-backend"
}

# ---------------------------------------------------------------------------
# Key Vault Access: Backend SP → Key Vault (Get, List)
# ---------------------------------------------------------------------------
resource "azurerm_key_vault_access_policy" "backend" {
  key_vault_id = var.key_vault_id
  tenant_id    = azuread_service_principal.backend_sp.application_tenant_id
  object_id    = azuread_service_principal.backend_sp.object_id

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
