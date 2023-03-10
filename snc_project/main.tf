resource "random_id" "prefix" {
  byte_length = 8
}

module "snc_resource_group" {
    source = "../modules/ResourceGroup"
    resource_group_name = var.snc_resource_group_name
    location = var.snc_resource_group_location
}

resource "azurerm_virtual_network" "sncvnet" {
  address_space       = ["10.52.0.0/16"]
  location            = module.snc_resource_group.resource_group_location
  name                = "${random_id.prefix.hex}-vn"
  resource_group_name = module.snc_resource_group.resource_group_name
}

resource "azurerm_subnet" "sncsubnet" {
  address_prefixes                               = ["10.52.0.0/24"]
  name                                           = "${random_id.prefix.hex}-sn"
  resource_group_name                            = module.snc_resource_group.resource_group_name
  virtual_network_name                           = azurerm_virtual_network.sncvnet.name
  enforce_private_link_endpoint_network_policies = true
}

# module "aks" {
#   source = "../.."

#   prefix                                  = "prefix-${random_id.prefix.hex}"
#   resource_group_name                     = local.resource_group.name
#   kubernetes_version                      = "1.24" # don't specify the patch version!
#   automatic_channel_upgrade               = "patch"
#   agents_availability_zones               = ["1", "2"]
#   agents_count                            = null
#   agents_max_count                        = 2
#   agents_max_pods                         = 100
#   agents_min_count                        = 1
#   agents_pool_name                        = "testnodepool"
#   agents_type                             = "VirtualMachineScaleSets"
#   azure_policy_enabled                    = true
#   client_id                               = var.client_id
#   client_secret                           = var.client_secret
#   disk_encryption_set_id                  = azurerm_disk_encryption_set.des.id
#   enable_auto_scaling                     = true
#   enable_host_encryption                  = true
#   http_application_routing_enabled        = true
#   ingress_application_gateway_enabled     = true
#   ingress_application_gateway_name        = "${random_id.prefix.hex}-agw"
#   ingress_application_gateway_subnet_cidr = "10.52.1.0/24"
#   local_account_disabled                  = true
#   log_analytics_workspace_enabled         = true
#   maintenance_window = {
#     allowed = [
#       {
#         day   = "Sunday",
#         hours = [22, 23]
#       },
#     ]
#     not_allowed = [
#       {
#         start = "2035-01-01T20:00:00Z",
#         end   = "2035-01-01T21:00:00Z"
#       },
#     ]
#   }
#   net_profile_dns_service_ip        = "10.0.0.10"
#   net_profile_docker_bridge_cidr    = "170.10.0.1/16"
#   net_profile_service_cidr          = "10.0.0.0/16"
#   network_plugin                    = "azure"
#   network_policy                    = "azure"
#   os_disk_size_gb                   = 60
#   private_cluster_enabled           = true
#   rbac_aad                          = true
#   rbac_aad_managed                  = true
#   role_based_access_control_enabled = true
#   sku_tier                          = "Paid"
#   vnet_subnet_id                    = azurerm_subnet.test.id

#   agents_labels = {
#     "node1" : "label1"
#   }
#   agents_tags = {
#     "Agent" : "agentTag"
#   }
# }