resource "null_resource" "build_and_publish" {
  provisioner "local-exec" {
    command = <<EOT
      az functionapp deployment source config-zip -g ${var.function_app_resource_group} -n ${var.function_app_name} --src ${var.deployment_package_path}
    EOT
  }
}