resource "null_resource" "publish" {
  provisioner "local-exec" {
    command = <<EOT
      az functionapp deployment source config-zip -g ${var.function_app_resource_group} -n ${var.function_app_name} --src ${var.deployment_package_path}
    EOT
  }
}

data "azurerm_function_app_host_keys" "main" {
  name                = var.function_app_name
  resource_group_name = var.function_app_resource_group
}
