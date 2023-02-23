########
# DATA #
########

# Data From Existing Infrastructure

# data "terraform_remote_state" "existing-lz" {
#   backend = "azurerm"

#   config = {
#     # storage_account_name = var.state_sa_name
#     # container_name       = var.container_name
#     storage_account_name = "snctfstatestorage"
#     container_name       = "snc"
#     key                  = "lz-net"
#     access_key = "uR2X8j74ilSh9T2TT0on+R0mbVwRtiY1TIlILxhbkv2cU9anQ/nkLIP3sVKqVDFM5CrAam+uwhEt+AStGV0tsA=="
#     # access_key = var.access_key
#   }
# }

# data "terraform_remote_state" "aks-support" {
#   backend = "azurerm"

#   config = {
#     # storage_account_name = var.state_sa_name
#     # container_name       = var.container_name
#     storage_account_name = "snctfstatestorage"
#     container_name       = "snc"
#     key                  = "aks-support"
#     access_key = "uR2X8j74ilSh9T2TT0on+R0mbVwRtiY1TIlILxhbkv2cU9anQ/nkLIP3sVKqVDFM5CrAam+uwhEt+AStGV0tsA=="
#     # access_key = var.access_key
#   }
# }

# data "terraform_remote_state" "aad" {
#   backend = "azurerm"

#   config = {
#     # storage_account_name = var.state_sa_name
#     storage_account_name = "snctfstatestorage"
#     container_name       = "snc"
#     # container_name       = var.container_name
#     key                  = "aad"
#     access_key = "uR2X8j74ilSh9T2TT0on+R0mbVwRtiY1TIlILxhbkv2cU9anQ/nkLIP3sVKqVDFM5CrAam+uwhEt+AStGV0tsA=="
#     # access_key = var.access_key
#   }

# }

data "azurerm_client_config" "current" {}
