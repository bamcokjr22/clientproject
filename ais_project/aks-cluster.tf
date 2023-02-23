#############
# RESOURCES #
#############

# Resource Group for AKS Components
# This RG uses the same region location as the Landing Zone Network. 
# resource "azurerm_resource_group" "rg-aks" {
#   name     = "${data.terraform_remote_state.existing-lz.outputs.lz_rg_name}-aks"
#   location = data.terraform_remote_state.existing-lz.outputs.lz_rg_location
# }

resource "azurerm_resource_group" "rg-aks" {
  name     = "snc-ais-aks-rg"
  location = "Central US"
}

resource "azurerm_container_registry" "acr" {
  name                = "sncContainerRegistry"
  resource_group_name = azurerm_resource_group.rg-aks.name
  location            = azurerm_resource_group.rg-aks.location
  sku                 = "Premium"
}

# MSI for Kubernetes Cluster (Control Plane)
# This ID is used by the AKS control plane to create or act on other resources in Azure.
# It is referenced in the "identity" block in the azurerm_kubernetes_cluster resource.

resource "azurerm_user_assigned_identity" "mi-aks-cp" {
  name                = "mi-${var.prefix}-aks-cp"
  resource_group_name = azurerm_resource_group.rg-aks.name
  location            = azurerm_resource_group.rg-aks.location
}

resource "azurerm_virtual_network" "aks_vnet" {
  name = "snc-ais-aks-vnet"
  resource_group_name = azurerm_resource_group.rg-aks.name
  location = azurerm_resource_group.rg-aks.location
  address_space = [ "10.0.0.0/16" ]
}

resource "azurerm_subnet" "aks_subnet" {
  name = "snc-ais-aks-subnet"
  resource_group_name = azurerm_resource_group.rg-aks.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes = [ "10.0.0.0/24" ]
}

resource "azurerm_public_ip" "snc_pip" {
  name                = "snc-pip"
  resource_group_name = azurerm_resource_group.rg-aks.name
  location            = azurerm_resource_group.rg-aks.location
  allocation_method   = "Dynamic"
  sku = "Standard"
}

# since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "${azurerm_virtual_network.aks_vnet.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.aks_vnet.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.aks_vnet.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.aks_vnet.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.aks_vnet.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.aks_vnet.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.aks_vnet.name}-rdrcfg"
}

resource "azurerm_application_gateway" "network" {
  name                = "snc-appgateway"
  resource_group_name = azurerm_resource_group.rg-aks.name
  location            = azurerm_resource_group.rg-aks.location

  sku {
    name     = "Standard_V2"
    tier     = "Standard_V2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.aks_subnet.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.snc_pip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}

# Role Assignments for Control Plane MSI

resource "azurerm_role_assignment" "aks-to-rt" {
  # scope                = data.terraform_remote_state.existing-lz.outputs.lz_rt_id
  scope                = azurerm_resource_group.rg-aks.id 
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.mi-aks-cp.principal_id
}

resource "azurerm_role_assignment" "aks-to-vnet" {
  # scope                = data.terraform_remote_state.existing-lz.outputs.lz_vnet_id
  scope                = azurerm_virtual_network.aks_vnet.id 
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.mi-aks-cp.principal_id

}

# Log Analytics Workspace for Cluster

resource "azurerm_log_analytics_workspace" "aks" {
  name                = "aks-la-01"
  resource_group_name           = azurerm_resource_group.rg-aks.name
  location            = azurerm_resource_group.rg-aks.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# AKS Cluster

module "aks" {
  source = "./modules/aks"
  depends_on = [
    azurerm_role_assignment.aks-to-vnet
  ]

  resource_group_name           = azurerm_resource_group.rg-aks.name
  location            = azurerm_resource_group.rg-aks.location
  prefix              = "aks-${var.prefix}"
  net_plugin          = var.net_plugin
  # vnet_subnet_id = data.terraform_remote_state.existing-lz.outputs.aks_subnet_id
  vnet_subnet_id         = azurerm_subnet.aks_subnet.id
  mi_aks_cp_id           = azurerm_user_assigned_identity.mi-aks-cp.id
  la_id = azurerm_log_analytics_workspace.aks.id
  # gateway_name = data.terraform_remote_state.existing-lz.outputs.gateway_name
  gateway_name = azurerm_application_gateway.network.name
  # gateway_id = data.terraform_remote_state.existing-lz.outputs.gateway_id
  gateway_id = azurerm_application_gateway.network.id

}

# These role assignments grant the groups made in "03-AAD" access to use
# The AKS cluster. 
resource "azurerm_role_assignment" "appdevs_user" {
  scope                = module.aks.aks_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  # principal_id         = data.terraform_remote_state.aad.outputs.appdev_object_id
  principal_id = data.azurerm_client_config.current.client_id
}

resource "azurerm_role_assignment" "aksops_admin" {
  scope                = module.aks.aks_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  # principal_id         = data.terraform_remote_state.aad.outputs.aksops_object_id
  principal_id = data.azurerm_client_config.current.client_id
}

# This role assigned grants the current user running the deployment admin rights
# to the cluster. In production, you should use just the AAD groups (above).
resource "azurerm_role_assignment" "aks_rbac_admin" {
  scope                = module.aks.aks_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id

}

# Role Assignment to Azure Container Registry from AKS Cluster
# This must be granted after the cluster is created in order to use the kubelet identity.

resource "azurerm_role_assignment" "aks-to-acr" {
  # scope                = data.terraform_remote_state.aks-support.outputs.container_registry_id
  scope = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_id

}

# Role Assignments for AGIC on AppGW
# This must be granted after the cluster is created in order to use the ingress identity.

resource "azurerm_role_assignment" "agic_appgw" {
  # scope                = data.terraform_remote_state.existing-lz.outputs.gateway_id
  scope = azurerm_application_gateway.network.id
  role_definition_name = "Contributor"
  principal_id         = module.aks.agic_id

}

