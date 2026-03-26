variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "env" {
  description = "Environment name (preprod or prod)"
  type        = string
}

variable "appgw_subnet_id" {
  description = "Subnet ID for the Application Gateway"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
