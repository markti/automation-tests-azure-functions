resource "null_resource" "http_test" {
  provisioner "local-exec" {
    command = "curl -sSf https://${var.function_app_default_hostname}/api/health || exit 1"
  }
}