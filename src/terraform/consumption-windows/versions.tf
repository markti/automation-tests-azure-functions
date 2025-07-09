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
  resource_provider_registrations = "none"
  subscription_id                 = "32cfe0af-c5cf-4a55-9d85-897b85a8f07c"
}
