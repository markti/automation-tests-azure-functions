resource "null_resource" "build_and_publish" {
  provisioner "local-exec" {
    command = <<EOT
      dotnet build ./src/dotnet/MyFunctionApp.csproj -c Release
      az functionapp deployment source config-zip -g ${var.function_app_resource_group} -n ${var.function_app_name} --src ./src/dotnet/MyFunctionApp/bin/Release/net6.0/publish.zip
    EOT
  }

  triggers = {
    app_version = filesha256("./src/MyFunctionApp/MyFunctionApp.csproj")
  }
}