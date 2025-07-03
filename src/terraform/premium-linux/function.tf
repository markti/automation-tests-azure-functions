resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}

resource "azurerm_user_assigned_identity" "function" {

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name                = "mi-${var.application_name}-${var.environment_name}"

}

# Grants the Azure Function Reader access to the Key Vault
resource "azurerm_role_assignment" "function_keyvault_reader" {

  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.function.principal_id

}

resource "azurerm_service_plan" "main" {
  name                = "asp-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "EP1"
}

resource "azurerm_storage_account" "function" {
  name                            = "st${random_string.suffix.result}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  shared_access_key_enabled       = false
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true # My GitHub Runners need to use the internet to access the storage account
}


# Allow User Assigned Identity Access to Function Operational Storage Account
resource "azurerm_role_assignment" "function_user_assigned_storage_contributor" {

  scope                = azurerm_storage_account.function.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_user_assigned_identity.function.principal_id

}

# Allow User Assigned Identity Access to Function Operational Storage Account Blob Storage
resource "azurerm_role_assignment" "function_user_assigned_storage_blob_data_owner" {

  scope                = azurerm_storage_account.function.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_user_assigned_identity.function.principal_id

}

# Allow System Assigned Identity Access to Function Operational Storage Account
resource "azurerm_role_assignment" "function_system_assigned_storage_contributor" {

  scope                = azurerm_storage_account.function.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_linux_function_app.main.identity[0].principal_id

}

# Allow System Assigned Identity Access to Function Operational Storage Account Blob Storage
resource "azurerm_role_assignment" "function_system_assigned_storage_blob_data_owner" {

  scope                = azurerm_storage_account.function.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_linux_function_app.main.identity[0].principal_id

}

resource "azurerm_linux_function_app" "main" {
  name                                           = "func-dotnet-${var.application_name}-${var.environment_name}-${random_string.suffix.result}"
  resource_group_name                            = azurerm_resource_group.main.name
  location                                       = azurerm_resource_group.main.location
  service_plan_id                                = azurerm_service_plan.main.id
  key_vault_reference_identity_id                = azurerm_user_assigned_identity.function.id
  storage_account_name                           = azurerm_storage_account.function.name
  storage_uses_managed_identity                  = true
  ftp_publish_basic_authentication_enabled       = false
  https_only                                     = true
  webdeploy_publish_basic_authentication_enabled = false

  identity {
    type = "SystemAssigned, UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.function.id
    ]
  }

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