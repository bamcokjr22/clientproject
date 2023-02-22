variable "snc_resource_group_name" {
  type = string
  default = "snc_aks_rg"
  description = "Name of the Resource Group to be created"
}

variable "snc_resource_group_location" {
  type = string
  default = "Central US"
  description = "Location of the Resource Group to be created"
}