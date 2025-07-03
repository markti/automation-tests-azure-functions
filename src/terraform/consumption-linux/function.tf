resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}

resource "azurerm_service_plan" "main" {
  name                = "asp-${var.application_name}-${var.environment_name}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_storage_account" "function" {
  name                     = "st${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "deployments" {
  name                  = "deployments"
  storage_account_id    = azurerm_storage_account.function.id
  container_access_type = "private"
}

resource "azurerm_storage_blob" "deployment_package" {
  name                   = "my-app.zip"
  storage_account_name   = azurerm_storage_account.function.name
  storage_container_name = azurerm_storage_container.deployments.name
  type                   = "Block"
  source                 = var.deployment_package_path
}

data "azurerm_storage_account_sas" "deployment_package" {
  connection_string = azurerm_storage_account.function.primary_connection_string

  https_only = true
  start      = "2025-07-03"
  expiry     = "2025-08-03"

  resource_types {
    service   = false
    container = false
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  permissions {
    read    = true
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
    filter  = false
    tag     = false
  }
}

resource "azurerm_linux_function_app" "main" {
  name                       = "func-dotnet-${var.application_name}-${var.environment_name}-${random_string.suffix.result}"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  service_plan_id            = azurerm_service_plan.main.id
  storage_account_name       = azurerm_storage_account.function.name
  storage_account_access_key = azurerm_storage_account.function.primary_access_key

  site_config {
    use_32_bit_worker = false

    application_stack {
      dotnet_version              = "8.0"
      use_dotnet_isolated_runtime = true
    }

    cors {
      allowed_origins     = ["https://portal.azure.com"]
      support_credentials = true
    }
  }

  # ZipDeploy extension with the appSetting WEBSITE_RUN_FROM_PACKAGE=1 is not supported only for Linux Consumption plan. 
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"       = "dotnet-isolated"
    "WEBSITE_RUN_FROM_PACKAGE"       = "${azurerm_storage_blob.deployment_package.url}${data.azurerm_storage_account_sas.deployment_package.sas}"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "false"
    "STORAGE_CONNECTION_STRING"      = azurerm_storage_account.function.primary_connection_string
    "QUEUE_CONNECTION_STRING"        = azurerm_storage_account.function.primary_connection_string
  }

}