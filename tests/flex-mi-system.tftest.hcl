provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

variables {
  application_name        = "fn-tf-tests"
  environment_name        = "test"
  location                = "westus3"
  deployment_package_path = "./dotnet-deployment.zip"
}

run "setup" {
  module {
    source = "./testing/setup"
  }

  variables {
    deployment_package_path = var.deployment_package_path
  }

  providers = {
    azurerm = azurerm
  }

  assert {
    condition     = length(data.local_sensitive_file.dotnet_deployment.id) > 0
    error_message = ".NET Deployment Package must be available"
  }
}

run "provision" {

  command = apply

  module {
    source = "./src/terraform/flex-mi-system"
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

run "deploy" {

  module {
    source = "./testing/deploy-azure-fn"
  }

  variables {
    function_app_name           = run.provision.function_app_name
    function_app_resource_group = run.provision.resource_group_name
    deployment_package_path     = var.deployment_package_path
  }

  providers = {
    azurerm = azurerm
  }

  assert {
    condition     = length(null_resource.publish.id) > 0
    error_message = "Null Resource Should be OK"
  }

  assert {
    condition     = length(data.azurerm_function_app_host_keys.main.default_function_key) > 0
    error_message = "Function Key should be OK"
  }
}

run "healthcheck" {

  module {
    source = "./testing/healthcheck-azure-fn"
  }

  variables {
    endpoint = "https://${run.provision.function_app_default_hostname}/api/Function1?code=${run.deploy.function_key}"
  }

  providers = {
    azurerm = azurerm
  }

  assert {
    condition     = data.http.endpoint.status_code == 200
    error_message = "Function Endpoint should be OK"
  }

  assert {
    condition     = data.http.endpoint.body == "Welcome to Azure Functions!"
    error_message = "Function Endpoint should return the correct content"
  }
}