resource "azurerm_monitor_action_group" "cpu" {
  name                = "ag-cpu-${local.resource_suffix}"
  resource_group_name = data.azurerm_resource_group.nimbus.name
  short_name          = "NimbusCPU"
  location            = "global"
  tags                = local.common_tags

  email_receiver {
    name                    = "NimbusShop CPU alert"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_metric_alert" "web_cpu" {
  name                     = "alert-cpu-${local.resource_suffix}"
  resource_group_name      = data.azurerm_resource_group.nimbus.name
  description              = "Alerte si le CPU moyen d'une VM web dépasse 80 % pendant 5 minutes."
  severity                 = 2
  frequency                = "PT1M"
  window_size              = "PT5M"
  scopes                   = azurerm_linux_virtual_machine.web[*].id
  target_resource_type     = "Microsoft.Compute/virtualMachines"
  target_resource_location = var.location
  tags                     = local.common_tags

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.cpu.id
  }
}

resource "random_password" "key_vault_secret" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_string" "key_vault_name_suffix" {
  length  = 8
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "azurerm_key_vault" "nimbus" {
  name                = "kvnimbus10${random_string.key_vault_name_suffix.result}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.nimbus.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  soft_delete_retention_days      = 7
  purge_protection_enabled        = false
  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = false

  tags = local.common_tags

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = ["Get", "List", "Set"]
  }
}

resource "azurerm_key_vault_secret" "nimbus" {
  name         = "nimbus-generated-password"
  key_vault_id = azurerm_key_vault.nimbus.id
  value        = random_password.key_vault_secret.result

  depends_on = [azurerm_key_vault.nimbus]
}
