variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "suffix" {
  description = "Random suffix for globally unique names"
  type        = string
}

variable "storage_account_primary_web_host" {
  description = "Primary web host for the storage account static website"
  type        = string
}

variable "agc_fqdn" {
  description = "Fully Qualified Domain Name of the Application Gateway for Containers (AGC) frontend"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
