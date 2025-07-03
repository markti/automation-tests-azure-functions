data "azurerm_function_app_host_keys" "main" {
  name                = var.function_app_name
  resource_group_name = var.function_app_resource_group
}
