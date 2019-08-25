provider "azurerm" {
  version = "~> 1.27"
}


resource "azurerm_resource_group" "resourceGroup" {
  name  = "terraform"
  location = "eastus"

  tags = {
    environment = "test"
  }
}
