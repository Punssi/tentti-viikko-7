terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
  subscription_id       = var.subscription_id
  tenant_id             = var.tenant_id
}

#Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = "westeurope"
}
