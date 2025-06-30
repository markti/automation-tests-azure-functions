provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

variables {
  location         = "westus3"
}

run "setup" {
  module {
    source = "./testing/setup"
  }
  providers = {
    azurerm = azurerm
  }
}

run "provision" {

command = apply

  module {
    source = "./src/terraform/consumption-linux"
  }

  variables {
  }

  providers = {
    azurerm = azurerm
  }

  assert {
    condition     = length(module.provision.resource_group_name) > 0
    error_message = "Must have a valid Resource Group Name"
  }
}