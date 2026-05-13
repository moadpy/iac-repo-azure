variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
}

variable "suffix" {
  description = "Random suffix for globally unique names"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Monitoring — Application Insights
# ---------------------------------------------------------------------------
variable "appinsights_connection_string" {
  description = "Application Insights connection string for function telemetry"
  type        = string
  sensitive   = true
  default     = ""
}

# ---------------------------------------------------------------------------
# Azure OpenAI configuration (endpoints only — auth via Managed Identity)
# ---------------------------------------------------------------------------
variable "openai_endpoint" {
  description = "Azure OpenAI endpoint URL"
  type        = string
  default     = ""
}

variable "openai_api_version" {
  description = "Azure OpenAI API version"
  type        = string
  default     = "2024-07-01-preview"
}

variable "openai_embedding_deployment" {
  description = "Azure OpenAI embedding deployment name"
  type        = string
  default     = "text-embedding-3-small"
}

# ---------------------------------------------------------------------------
# Azure AI Search configuration (endpoint only — auth via Managed Identity)
# ---------------------------------------------------------------------------
variable "search_endpoint" {
  description = "Azure AI Search endpoint URL"
  type        = string
  default     = ""
}

variable "search_evidence_index_name" {
  description = "Azure AI Search index name for evidence documents"
  type        = string
  default     = "rca-evidence-index"
}

variable "search_runbook_index_name" {
  description = "Azure AI Search index name for runbook documents"
  type        = string
  default     = "rca-runbook-index"
}

# ---------------------------------------------------------------------------
# GitHub integration
# ---------------------------------------------------------------------------
variable "github_webhook_secret" {
  description = "GitHub webhook secret for signature validation"
  type        = string
  sensitive   = true
  default     = ""
}

variable "github_token" {
  description = "GitHub Personal Access Token for fetching PR diffs"
  type        = string
  sensitive   = true
  default     = ""
}

# ---------------------------------------------------------------------------
# Blob trigger — Runbooks storage connection
# ---------------------------------------------------------------------------
variable "runbooks_storage_connection_string" {
  description = "Connection string for the ML storage account (where runbooks are uploaded)"
  type        = string
  sensitive   = true
  default     = ""
}
