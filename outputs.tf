# ===========================================================================
# Root outputs.tf — Key values for .env files and CI/CD secrets
# ===========================================================================

# ---------------------------------------------------------------------------
# Azure AD / Identity
# ---------------------------------------------------------------------------
output "AZURE_TENANT_ID" {
  description = "Azure AD Tenant ID"
  value       = data.azurerm_client_config.current.tenant_id
}

output "AZURE_CLIENT_ID" {
  description = "Backend SP Client ID → backend/.env"
  value       = module.identity.backend_client_id
}

output "AZURE_CLIENT_SECRET" {
  description = "Backend SP Client Secret → backend/.env (sensitive)"
  value       = module.identity.backend_client_secret
  sensitive   = true
}

output "GITHUB_ACTIONS_CLIENT_ID" {
  description = "GitHub Actions SP Client ID → GitHub Secrets"
  value       = module.identity.github_actions_client_id
}

output "GITHUB_ACTIONS_CLIENT_SECRET" {
  description = "GitHub Actions SP Client Secret → GitHub Secrets (sensitive)"
  value       = module.identity.github_actions_client_secret
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Azure OpenAI
# ---------------------------------------------------------------------------
output "AZURE_OPENAI_ENDPOINT" {
  description = "Azure OpenAI endpoint → backend/.env"
  value       = module.azure_openai.openai_endpoint
}

output "AZURE_OPENAI_DEPLOYMENT_NAME" {
  description = "Chat model deployment name → backend/.env"
  value       = module.azure_openai.chat_deployment_name
}

output "AZURE_OPENAI_EMBEDDING_DEPLOYMENT" {
  description = "Embedding deployment name → backend/.env"
  value       = module.azure_openai.embedding_deployment_name
}

# ---------------------------------------------------------------------------
# Azure AI Search
# ---------------------------------------------------------------------------
output "AZURE_SEARCH_ENDPOINT" {
  description = "Azure AI Search endpoint → backend/.env"
  value       = module.ai_search.search_endpoint
}

# ---------------------------------------------------------------------------
# Cosmos DB
# ---------------------------------------------------------------------------
output "COSMOS_DB_ENDPOINT" {
  description = "Cosmos DB endpoint → backend/.env"
  value       = module.cosmos_db.cosmosdb_endpoint
}

output "COSMOS_DB_DATABASE_NAME" {
  description = "Cosmos DB database name → backend/.env"
  value       = module.cosmos_db.cosmosdb_database_name
}

output "COSMOS_DB_INCIDENTS_CONTAINER" {
  description = "Cosmos DB container name → backend/.env"
  value       = module.cosmos_db.cosmosdb_container_name
}

# ---------------------------------------------------------------------------
# Storage
# ---------------------------------------------------------------------------
output "STORAGE_ACCOUNT_NAME" {
  description = "Storage account name → GitHub Secrets / blob sync"
  value       = module.storage.storage_account_name
}

# ---------------------------------------------------------------------------
# Azure ML
# ---------------------------------------------------------------------------
output "AZURE_ML_WORKSPACE_NAME" {
  description = "Azure ML workspace name"
  value       = module.azure_ml.workspace_name
}

# ---------------------------------------------------------------------------
# ACR
# ---------------------------------------------------------------------------
output "ACR_LOGIN_SERVER" {
  description = "ACR login server URL"
  value       = module.acr.acr_login_server
}

# ---------------------------------------------------------------------------
# Dev VM (conditional)
# ---------------------------------------------------------------------------
output "DEV_VM_PUBLIC_IP" {
  description = "Public IP of the dev VM (if deployed)"
  value       = var.deploy_dev_vm ? module.dev_vm[0].vm_public_ip : null
}

output "DEV_VM_SSH_COMMAND" {
  description = "SSH command to connect to the dev VM (if deployed)"
  value       = var.deploy_dev_vm ? module.dev_vm[0].ssh_command : null
}

# ---------------------------------------------------------------------------
# Azure Functions (Knowledge Base Ingestion)
# ---------------------------------------------------------------------------
output "FUNCTION_APP_NAME" {
  description = "Function App name — used in deployment: func azure functionapp publish <name>"
  value       = module.functions.function_app_name
}

output "FUNCTION_APP_HOSTNAME" {
  description = "Function App default hostname — base URL for the GitHub webhook"
  value       = module.functions.function_app_default_hostname
}

# ---------------------------------------------------------------------------
# AKS (conditional)
# ---------------------------------------------------------------------------
output "AKS_CLUSTER_NAME" {
  description = "Name of the AKS cluster (if deployed)"
  value       = var.deploy_aks ? module.aks[0].aks_name : null
}

output "AKS_CLUSTER_FQDN" {
  description = "API server FQDN of the AKS cluster (if deployed)"
  value       = var.deploy_aks ? module.aks[0].cluster_fqdn : null
}

output "AKS_OIDC_ISSUER_URL" {
  description = "OIDC issuer URL for Workload Identity federation (if deployed)"
  value       = var.deploy_aks ? module.aks[0].oidc_issuer_url : null
}

output "AKS_KUBE_CONFIG_RAW" {
  description = "Raw kubeconfig — pipe to ~/.kube/config or use with KUBECONFIG (sensitive)"
  value       = var.deploy_aks ? module.aks[0].kube_config_raw : null
  sensitive   = true
}

output "AKS_NODE_RESOURCE_GROUP" {
  description = "Auto-generated resource group that holds AKS infrastructure nodes"
  value       = var.deploy_aks ? module.aks[0].node_resource_group : null
}


