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
}

run "provision" {

command = apply

  module {
    source = "./src/terraform/consumption-windows"
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

run "deploy" {
  module {
    source = "./testing/deploy-azure-fn"
  }

  variables {
    function_app_name            = module.provision.function_app_name
    function_app_resource_group  = module.provision.resource_group_name
  }

  providers = {
    azurerm = azurerm
  }
}

run "health-check" {
  module {
    source = "./testing/healthcheck-azure-fn"
  }

  variables {
    function_app_default_hostname = module.provision.function_app_default_hostname
  }

  providers = {
    azurerm = azurerm
  }
}
