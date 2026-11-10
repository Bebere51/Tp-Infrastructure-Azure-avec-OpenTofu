data "azurerm_resource_group" "nimbus" {
  name = var.resource_group_name
}

data "azurerm_client_config" "current" {}

locals {
  resource_suffix = "nimbus-${var.group_number}"

  common_tags = {
    projet = "NimbusShop"
    owner  = var.owner
    env    = var.environment
  }
}
