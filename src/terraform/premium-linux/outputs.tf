output "resource_group_name" {
  value = azurerm_resource_group.main.name
}
output "function_app_name" {
  value = azurerm_linux_function_app.main.name
}
output "function_app_default_hostname" {
  value = azurerm_linux_function_app.main.default_hostname
}