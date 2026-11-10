output "website_url" {
  description = "Public URL of the NimbusShop website."
  value       = "http://${azurerm_public_ip.web.ip_address}"
}

output "web_vm_private_ips" {
  description = "Private IP addresses assigned to the two web VMs."
  value       = [for nic in azurerm_network_interface.web : nic.private_ip_address]
}

output "jumpbox_public_ip" {
  description = "Public IPv4 address of the SSH-restricted jumpbox."
  value       = azurerm_public_ip.jumpbox.ip_address
}
