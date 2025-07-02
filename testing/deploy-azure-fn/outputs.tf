output "function_key" {
  value     = data.azurerm_function_app_host_keys.main.default_function_key
  sensitive = true
}