# ===========================================================================
# Module: network — Input Variables
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

variable "vnet_cidr" {
  description = "CIDR block for the AKS VNet"
  type        = string
}

variable "aks_subnet_cidr" {
  description = "CIDR block for the AKS nodes subnet"
  type        = string
}

variable "agc_subnet_cidr" {
  description = "CIDR block for the AGC subnet"
  type        = string
  default     = "10.1.4.0/24"
}

variable "dev_subnet_cidr" {
  description = "CIDR block for the Dev VM / Jumpbox subnet"
  type        = string
}

variable "pe_subnet_cidr" {
  description = "CIDR block for the Private Endpoints subnet"
  type        = string
}

variable "functions_subnet_cidr" {
  description = "CIDR block for the Azure Functions subnet"
  type        = string
}

variable "deploy_developer_bastion" {
  description = "Whether to deploy a Developer SKU Bastion directly inside the Spoke VNet."
  type        = bool
  default     = false
}

variable "hub_vnet_name" {
  description = "Name of the Hub VNet for peering."
  type        = string
  default     = ""
}

variable "hub_vnet_resource_group_name" {
  description = "Resource group name of the Hub VNet."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
