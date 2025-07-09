terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.35.0"
    }
  }

  required_version = "~> 1.2"
}

provider "azurerm" {
  features {}
}
