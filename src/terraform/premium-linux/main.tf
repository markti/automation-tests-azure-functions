

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "main" {
  name     = "rg-${random_string.suffix.result}"
  location = var.location
}
