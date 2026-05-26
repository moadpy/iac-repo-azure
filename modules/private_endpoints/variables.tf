# ===========================================================================
# Module: private_endpoints — Input Variables
# ===========================================================================

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "suffix" {
  description = "Random suffix for globally unique names"
  type        = string
}

variable "vnet_id" {
  description = "Resource ID of the Spoke VNet"
  type        = string
}

variable "pe_subnet_id" {
  description = "Resource ID of the subnet dedicated for Private Endpoints"
  type        = string
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault"
  type        = string
}

variable "storage_account_id" {
  description = "Resource ID of the main ML Storage Account"
  type        = string
}

variable "function_storage_account_id" {
  description = "Resource ID of the Functions App storage account"
  type        = string
}

variable "acr_id" {
  description = "Resource ID of the Azure Container Registry"
  type        = string
}

variable "cosmosdb_account_id" {
  description = "Resource ID of the Cosmos DB account"
  type        = string
}

variable "openai_account_id" {
  description = "Resource ID of the Azure OpenAI account"
  type        = string
}

variable "search_service_id" {
  description = "Resource ID of the Azure AI Search service"
  type        = string
}

variable "ml_workspace_id" {
  description = "Resource ID of the Azure Machine Learning workspace"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
