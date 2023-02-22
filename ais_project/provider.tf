terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.61"
    }
    random = {
      version = ">=3.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "SNC-TFSTATE-RG"   # Partial configuration, provided during "terraform init"
    storage_account_name = "snctfstatestorage"   # Partial configuration, provided during "terraform init"
    container_name       = "snc"   # Partial configuration, provided during "terraform init"
    key                  = "aks"
  }
}

provider "azurerm" {
  features {}
}
