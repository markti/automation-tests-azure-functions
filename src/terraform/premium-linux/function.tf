resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}

resource "azurerm_service_plan" "main" {
  name                = "asp-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "EP2"
}
