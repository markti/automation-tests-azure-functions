data "local_file" "dotnet_deployment" {
  filename = var.deployment_package_path
}
