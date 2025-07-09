# Inspired by the Official Bicep Sample:
# https://github.com/Azure-Samples/function-app-arm-templates/blob/main/function-app-linux-consumption/README.md

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

variables {
  application_name        = "fn-tf-tests"
  environment_name        = "test"
  location                = "canadacentral"
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

# Provision and deploy the Azure Function App
run "provision" {

  command = apply

  module {
    source = "./src/terraform/consumption-linux"
  }

  variables {
    deployment_package_path = var.deployment_package_path
  }

  providers = {
    azurerm = azurerm
  }

  assert {
    condition     = length(azurerm_resource_group.main.name) > 0
    error_message = "Must have a valid Resource Group Name"
  }
}

# Get the Azure Function Access Key
run "authn" {

  module {
    source = "./testing/authn-azure-fn"
  }

  variables {
    function_app_name           = run.provision.function_app_name
    function_app_resource_group = run.provision.resource_group_name
  }

  providers = {
    azurerm = azurerm
  }

  assert {
    condition     = length(data.azurerm_function_app_host_keys.main.default_function_key) > 0
    error_message = "Function Key should be OK"
  }
}

# Verify the Azure Function is deployed and accessible
run "healthcheck" {

  module {
    source = "./testing/healthcheck-azure-fn"
  }

  variables {
    endpoint = "https://${run.provision.function_app_default_hostname}/api/Function1?code=${run.authn.function_key}"
  }

  providers = {
    azurerm = azurerm
  }

  assert {
    condition     = data.http.endpoint.status_code == 200
    error_message = "Function Endpoint should be OK"
  }

  assert {
    condition     = data.http.endpoint.response_body == "Welcome to Azure Functions!"
    error_message = "Function Endpoint should return the correct content"
  }
}
