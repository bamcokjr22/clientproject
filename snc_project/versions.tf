terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.44.1"
    }
  }

  backend "azurerm" {
    resource_group_name     = "SNC-TFSTATE-RG"
    storage_account_name    = "snctfstatestorage"
    container_name          = "snc"
    key                     = "snc.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}