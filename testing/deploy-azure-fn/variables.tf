variable "function_app_name" {
  type        = string
  description = "Name of the Azure Function App"
}
variable "function_app_resource_group" {
  type        = string
  description = "Resource Group for the Azure Function App"
}
variable "deployment_package_path" {
  type = string
}