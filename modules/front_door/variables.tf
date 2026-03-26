variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "env" {
  description = "Deployment environment (preprod or prod)"
  type        = string
}

variable "frontend_web_endpoint" {
  description = "Primary web endpoint URL of the static website Blob storage account"
  type        = string
}

variable "appgw_public_ip" {
  description = "Public IP address of the Application Gateway"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
