resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}

resource "azurerm_user_assigned_identity" "function" {
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  name                = "mi-${var.application_name}-${var.environment_name}-${random_string.suffix.result}"
}

resource "azurerm_service_plan" "main" {
  name                = "asp-${var.application_name}-${var.environment_name}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "FC1"
}

resource "azurerm_storage_account" "function" {
  name                     = "st${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "flex" {
  name                  = "flex"
  storage_account_id    = azurerm_storage_account.function.id
  container_access_type = "private"
}

resource "azurerm_function_app_flex_consumption" "main" {
  name                = "func-dotnet-${var.application_name}-${var.environment_name}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.function.id]
  }

  storage_container_type            = "blobContainer"
  storage_container_endpoint        = "${azurerm_storage_account.function.primary_blob_endpoint}${azurerm_storage_container.flex.name}"
  storage_authentication_type       = "UserAssignedIdentity"
  storage_user_assigned_identity_id = azurerm_user_assigned_identity.function.id
  runtime_name                      = "dotnet-isolated"
  runtime_version                   = "8.0"
  maximum_instance_count            = 50
  instance_memory_in_mb             = 2048

  site_config {}
}

resource "azurerm_role_assignment" "storage_owner" {
  scope                = azurerm_storage_account.function.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_user_assigned_identity.function.principal_id
}
