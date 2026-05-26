# ===========================================================================
# Module: agc — Input Variables
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

variable "agc_subnet_id" {
  description = "Resource ID of the subnet delegated to AGC"
  type        = string
}

variable "aks_oidc_issuer_url" {
  description = "OIDC Issuer URL of the AKS cluster (for Workload Identity)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
