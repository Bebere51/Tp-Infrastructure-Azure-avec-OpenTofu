resource "azurerm_public_ip" "web" {
  name                = "pip-${local.resource_suffix}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.nimbus.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

resource "azurerm_lb" "web" {
  name                = "lb-${local.resource_suffix}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.nimbus.name
  sku                 = "Standard"
  tags                = local.common_tags

  frontend_ip_configuration {
    name                 = "frontend-${local.resource_suffix}"
    public_ip_address_id = azurerm_public_ip.web.id
  }
}

resource "azurerm_lb_backend_address_pool" "web" {
  name            = "backend-${local.resource_suffix}"
  loadbalancer_id = azurerm_lb.web.id
}

resource "azurerm_lb_probe" "web" {
  name            = "probe-http-${local.resource_suffix}"
  loadbalancer_id = azurerm_lb.web.id
  protocol        = "Http"
  port            = 80
  request_path    = "/health"
}

resource "azurerm_lb_rule" "web" {
  name                           = "rule-http-${local.resource_suffix}"
  loadbalancer_id                = azurerm_lb.web.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_lb.web.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web.id]
  probe_id                       = azurerm_lb_probe.web.id
  disable_outbound_snat          = true
}

resource "azurerm_lb_outbound_rule" "web" {
  name                    = "outbound-${local.resource_suffix}"
  loadbalancer_id         = azurerm_lb.web.id
  protocol                = "All"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web.id

  frontend_ip_configuration {
    name = azurerm_lb.web.frontend_ip_configuration[0].name
  }
}
