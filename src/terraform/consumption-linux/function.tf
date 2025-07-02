resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}

resource "azurerm_service_plan" "main" {
  name                = "asp-${random_string.suffix.result}"
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

resource "azurerm_linux_function_app" "main" {
  name                       = "func-dotnet-${random_string.main.result}"
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

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"               = "dotnet-isolated"
    "WEBSITE_USE_PLACEHOLDER_DOTNETISOLATED" = 1
    "WEBSITE_RUN_FROM_PACKAGE"               = 1
    "SCM_DO_BUILD_DURING_DEPLOYMENT"         = "false"
    "STORAGE_CONNECTION_STRING"              = azurerm_storage_account.function.primary_connection_string
    "QUEUE_CONNECTION_STRING"                = azurerm_storage_account.function.primary_connection_string
  }

}