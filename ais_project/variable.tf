#############
# VARIABLES #
#############

variable "prefix" {}

variable "state_sa_name" {
    default = "snctfstatestorage"
}

variable "container_name" {
    default = "snc"
}

# variable "access_key" {}

variable "net_plugin" {
    default = "azure"  #Options are "azure" or "kubenet"
}
