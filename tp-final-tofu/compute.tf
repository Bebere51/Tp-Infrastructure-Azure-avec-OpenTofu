resource "azurerm_network_interface" "web" {
  count               = 2
  name                = "nic-web-${local.resource_suffix}-${count.index + 1}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.nimbus.name
  tags                = local.common_tags
  depends_on          = [azurerm_subnet_network_security_group_association.web]

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "web" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.web[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web.id
}

resource "azurerm_linux_virtual_machine" "web" {
  count                           = 2
  name                            = "vm-web-${local.resource_suffix}-${count.index + 1}"
  computer_name                   = "web-${var.group_number}-${count.index + 1}"
  location                        = var.location
  resource_group_name             = data.azurerm_resource_group.nimbus.name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.web[count.index].id]
  custom_data                     = filebase64("${path.module}/cloud-init.yaml")
  tags                            = local.common_tags
  depends_on                      = [azurerm_network_interface_backend_address_pool_association.web]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

resource "azurerm_public_ip" "jumpbox" {
  name                = "pip-jumpbox-${local.resource_suffix}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.nimbus.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

resource "azurerm_network_interface" "jumpbox" {
  name                = "nic-jumpbox-${local.resource_suffix}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.nimbus.name
  tags                = local.common_tags
  depends_on          = [azurerm_subnet_network_security_group_association.admin]

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.admin.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jumpbox.id
  }
}

resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                            = "vm-jumpbox-${local.resource_suffix}"
  computer_name                   = "jumpbox-${var.group_number}"
  location                        = var.location
  resource_group_name             = data.azurerm_resource_group.nimbus.name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.jumpbox.id]
  tags                            = local.common_tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
