# ===========================================================================
# Root variables.tf — All inputs for the modular infrastructure
# ===========================================================================

# ---------------------------------------------------------------------------
# Global
# ---------------------------------------------------------------------------
variable "subscription_id" {
  description = "Azure Subscription ID (required for AzureRM v4)"
  type        = string
  # No default to force the user or pipeline to provide it, or let them set ARM_SUBSCRIPTION_ID
  default = ""
}

variable "resource_group_name" {
  description = "Name of the pre-existing resource group (sandbox: SP cannot create RGs)"
  type        = string
  default     = "dev-env-rg"
}

variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be 'dev' or 'prod'."
  }
}

variable "location" {
  description = "Azure region for all resources (except OpenAI which may differ)"
  type        = string
  default     = "westeurope"
}

# ---------------------------------------------------------------------------
# Storage
# ---------------------------------------------------------------------------
variable "storage_container_name" {
  description = "Blob container name for ML data"
  type        = string
  default     = "ml-data-dev"
}

# ---------------------------------------------------------------------------
# Azure ML
# ---------------------------------------------------------------------------
variable "ml_workspace_name" {
  description = "Azure ML workspace name"
  type        = string
  default     = "aml-rca-dev"
}

# ---------------------------------------------------------------------------
# Azure OpenAI
# ---------------------------------------------------------------------------
variable "openai_location" {
  description = <<-EOT
    Azure region for Azure OpenAI.
    Must be a region where Azure OpenAI is available — not all regions support it.
    If you get a quota error, try: swedencentral, francecentral, or eastus2.
  EOT
  type        = string
  default     = "eastus"
}

variable "chat_model_name" {
  description = "Name of the chat model to deploy"
  type        = string
  default     = "gpt-5.4-mini"
}

variable "chat_model_version" {
  description = "Version of the chat model"
  type        = string
  default     = "2026-03-17"
}

variable "chat_sku_name" {
  description = "SKU name for chat deployment (Standard, DataZoneStandard, etc.)"
  type        = string
  default     = "DataZoneStandard"
}

variable "chat_sku_capacity" {
  description = "Capacity (TPU) for chat deployment"
  type        = number
  default     = 100
}

variable "embedding_model_name" {
  description = "Name of the embedding model to deploy"
  type        = string
  default     = "text-embedding-3-small"
}

variable "embedding_model_version" {
  description = "Version of the embedding model"
  type        = string
  default     = "1"
}

variable "embedding_sku_name" {
  description = "SKU name for embedding deployment"
  type        = string
  default     = "Standard"
}

variable "embedding_sku_capacity" {
  description = "Capacity (TPU) for embedding deployment"
  type        = number
  default     = 120
}

# ---------------------------------------------------------------------------
# Azure AI Search
# ---------------------------------------------------------------------------
variable "search_sku" {
  description = <<-EOT
    Azure AI Search SKU tier.
    "free"  — $0/month, 50 MB storage, 3 indexes. Use for POC/dev.
    "basic" — ~$73/month, 15 GB storage, 15 indexes. Use for staging/prod.
  EOT
  type        = string
  default     = "free"

  validation {
    condition     = contains(["free", "basic", "standard"], var.search_sku)
    error_message = "search_sku must be 'free', 'basic', or 'standard'."
  }
}

# ---------------------------------------------------------------------------
# Dev VM (optional — toggle with deploy_dev_vm)
# ---------------------------------------------------------------------------
variable "deploy_dev_vm" {
  description = "Whether to deploy the dev VM for backend development"
  type        = bool
  default     = true
}

variable "dev_vm_size" {
  description = "VM size for the dev VM"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "dev_vm_admin_username" {
  description = "Admin username for the dev VM"
  type        = string
  default     = "azureuser"
}

variable "dev_vm_ssh_public_key_path" {
  description = "Path to the SSH public key file for the dev VM"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

# ---------------------------------------------------------------------------
# Azure AI Search — Index Configuration
# ---------------------------------------------------------------------------
variable "search_evidence_index_name" {
  description = "Name of the Azure AI Search index for evidence documents"
  type        = string
  default     = "rca-evidence-index"
}

variable "search_runbook_index_name" {
  description = "Name of the Azure AI Search index for runbook documents"
  type        = string
  default     = "rca-runbook-index"
}

# ---------------------------------------------------------------------------
# GitHub Integration (for PR Ingestor Azure Function)
# ---------------------------------------------------------------------------
variable "github_webhook_secret" {
  description = "Shared secret for validating GitHub webhook signatures (X-Hub-Signature-256)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "github_token" {
  description = "GitHub Personal Access Token with 'repo' scope — used to fetch PR diffs"
  type        = string
  sensitive   = true
  default     = ""
}

# ---------------------------------------------------------------------------
# Tags
# ---------------------------------------------------------------------------
variable "tags" {
  description = "Additional tags to merge with default tags"
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# AKS (optional — toggle with deploy_aks)
# ---------------------------------------------------------------------------
variable "deploy_aks" {
  description = "Whether to deploy the AKS cluster (set false to skip in cost-sensitive envs)"
  type        = bool
  default     = false
}

variable "aks_kubernetes_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
  default     = "1.35"
}

variable "aks_sku_tier" {
  description = "AKS SKU tier: Free (no SLA) or Standard (99.95% SLA)"
  type        = string
  default     = "Free"

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.aks_sku_tier)
    error_message = "aks_sku_tier must be 'Free', 'Standard', or 'Premium'."
  }
}

variable "aks_system_node_vm_size" {
  description = "VM size for the AKS system node pool"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "aks_system_node_count" {
  description = "Number of nodes in the AKS system node pool"
  type        = number
  default     = 2
}

variable "aks_deploy_user_node_pool" {
  description = "Whether to add a dedicated user node pool (ML workloads)"
  type        = bool
  default     = false
}

variable "aks_user_node_vm_size" {
  description = "VM size for the AKS user node pool"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "aks_user_node_count" {
  description = "Number of nodes in the AKS user node pool"
  type        = number
  default     = 1
}

variable "aks_vnet_cidr" {
  description = "CIDR block for the AKS VNet (must not overlap with existing VNets)"
  type        = string
  default     = "10.1.0.0/16"
}

variable "aks_subnet_cidr" {
  description = "CIDR block for the AKS nodes subnet"
  type        = string
  default     = "10.1.0.0/22"
}

variable "aks_service_cidr" {
  description = "CIDR range for Kubernetes services (must not overlap with VNet or subnet)"
  type        = string
  default     = "10.200.0.0/16"
}

variable "aks_dns_service_ip" {
  description = "IP address for the Kubernetes DNS service (must be inside aks_service_cidr)"
  type        = string
  default     = "10.200.0.10"
}
