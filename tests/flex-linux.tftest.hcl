provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

variables {
  application_name = "fn-tf-tests"
  environment_name = "test"
  location         = "westus3"
}

run "setup" {
  module {
    source = "./testing/setup"
  }
  providers = {
    azurerm = azurerm
  }

  assert {
    condition     = length(data.local_file.dotnet_deployment.id) > 0
    error_message = ".NET Deployment Package must be available"
  }
}

run "provision" {

  command = apply

  module {
    source = "./src/terraform/flex"
  }

  variables {
  }

  providers = {
    azurerm = azurerm
  }

  assert {
    condition     = length(azurerm_resource_group.main.name) > 0
    error_message = "Must have a valid Resource Group Name"
  }
}