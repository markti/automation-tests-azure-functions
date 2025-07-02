output "resource_group_name" {
  value = azurerm_resource_group.main.name
}
output "function_app_name" {
  value = azurerm_function_app_flex_consumption.main.name
}
output "function_app_default_hostname" {
  value = azurerm_function_app_flex_consumption.main.default_hostname
}