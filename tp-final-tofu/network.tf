resource "azurerm_virtual_network" "nimbus" {
  name                = "vnet-${local.resource_suffix}"
  address_space       = ["10.${var.group_number}.0.0/16"]
  location            = var.location
  resource_group_name = data.azurerm_resource_group.nimbus.name
  tags                = local.common_tags
}

resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = data.azurerm_resource_group.nimbus.name
  virtual_network_name = azurerm_virtual_network.nimbus.name
  address_prefixes     = ["10.${var.group_number}.1.0/24"]
}

resource "azurerm_subnet" "admin" {
  name                 = "snet-admin"
  resource_group_name  = data.azurerm_resource_group.nimbus.name
  virtual_network_name = azurerm_virtual_network.nimbus.name
  address_prefixes     = ["10.${var.group_number}.2.0/24"]
}

resource "azurerm_network_security_group" "web" {
  name                = "nsg-web-${local.resource_suffix}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.nimbus.name
  tags                = local.common_tags

  security_rule {
    name                       = "Allow-HTTP-Internet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Load-Balancer-Probe"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH-From-Admin-Subnet"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.${var.group_number}.2.0/24"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "admin" {
  name                = "nsg-admin-${local.resource_suffix}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.nimbus.name
  tags                = local.common_tags

  security_rule {
    name                       = "Allow-SSH-From-Authorized-IP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ssh_ip
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

resource "azurerm_subnet_network_security_group_association" "admin" {
  subnet_id                 = azurerm_subnet.admin.id
  network_security_group_id = azurerm_network_security_group.admin.id
}
