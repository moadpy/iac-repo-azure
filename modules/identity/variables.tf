variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "resource_group_id" {
  description = "ID of the resource group (for Contributor role assignment)"
  type        = string
}

variable "suffix" {
  description = "Random suffix for globally unique names"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string
}

variable "caller_object_id" {
  description = "Object ID of the Terraform caller (current user/SP)"
  type        = string
}

# --- Resource IDs for RBAC scoping ---
variable "openai_account_id" {
  description = "ID of the Azure OpenAI Cognitive Account"
  type        = string
}

variable "search_service_id" {
  description = "ID of the Azure AI Search service"
  type        = string
}

variable "cosmosdb_account_id" {
  description = "ID of the Cosmos DB account"
  type        = string
}

variable "cosmosdb_account_name" {
  description = "Name of the Cosmos DB account"
  type        = string
}

variable "storage_account_id" {
  description = "ID of the Storage Account"
  type        = string
}

variable "function_app_principal_id" {
  description = "Principal ID of the Function App Managed Identity"
  type        = string
}

variable "aks_cluster_id" {
  description = "Resource ID of the AKS cluster (optional, for user RBAC)"
  type        = string
  default     = ""
}

variable "aks_cluster_identity_principal_id" {
  description = "Principal ID of the AKS cluster identity"
  type        = string
  default     = ""
}

variable "agc_subnet_id" {
  description = "Resource ID of the AGC subnet"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "backend_client_id" {
  type    = string
  default = ""
}

variable "backend_sp_object_id" {
  type    = string
  default = ""
}

variable "backend_client_secret" {
  type    = string
  default = ""
}

variable "github_actions_client_id" {
  type    = string
  default = ""
}

variable "github_actions_sp_object_id" {
  type    = string
  default = ""
}

variable "github_actions_client_secret" {
  type    = string
  default = ""
}

variable "aks_oidc_issuer_url" {
  description = "OIDC Issuer URL of the AKS cluster"
  type        = string
  default     = ""
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault"
  type        = string
  default     = ""
}

variable "deploy_aks" {
  description = "Whether AKS is being deployed (used for deterministic count)"
  type        = bool
  default     = false
}
