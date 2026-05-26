# ===========================================================================
# Module: agc (Application Gateway for Containers / ALB)
# Purpose: Provision the ALB infrastructure for AKS Ingress
# ===========================================================================

# In the ALB-controller managed model (Strategy B), the load balancer, frontend, and subnet
# association are provisioned dynamically by the ALB controller running inside Kubernetes, 
# not by Terraform HCL. We only deploy the required Managed Identity and RBAC roles here.

# ---------------------------------------------------------------------------
# Identity for ALB Controller (Workload Identity)
# ---------------------------------------------------------------------------
resource "azurerm_user_assigned_identity" "alb_controller" {
  name                = "id-alb-controller-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# RBAC: ALB Identity -> Resource Group (Configuration Manager)
resource "azurerm_role_assignment" "alb_controller_manager" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  role_definition_name = "AppGw for Containers Configuration Manager"
  principal_id         = azurerm_user_assigned_identity.alb_controller.principal_id
}

# RBAC: ALB Identity -> AGC Subnet (Network Contributor)
resource "azurerm_role_assignment" "alb_controller_network" {
  scope                = var.agc_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.alb_controller.principal_id
}

# Federated Identity Credential (Trust the alb-controller pod in azure-alb-system namespace)
resource "azurerm_federated_identity_credential" "alb_controller" {
  name                       = "fed-alb-controller-${var.suffix}"
  audience                   = ["api://AzureADTokenExchange"]
  issuer                     = var.aks_oidc_issuer_url
  user_assigned_identity_id  = azurerm_user_assigned_identity.alb_controller.id
  subject                    = "system:serviceaccount:azure-alb-system:alb-controller-sa"
}

data "azurerm_client_config" "current" {}
