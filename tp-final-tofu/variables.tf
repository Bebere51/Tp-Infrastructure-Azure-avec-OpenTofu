variable "subscription_id" {
  description = "Azure subscription ID. Leave null to use the subscription selected by az login."
  type        = string
  default     = null
  nullable    = true
}

variable "resource_group_name" {
  description = "Name of the existing Azure Resource Group to use."
  type        = string
  default     = "rg-nimbus-10"
}

variable "location" {
  description = "Azure region selected for the TP."
  type        = string
  default     = "polandcentral"
}

variable "group_number" {
  description = "Group number used in the network address space and resource names."
  type        = number
  default     = 10

  validation {
    condition     = var.group_number >= 1 && var.group_number <= 254 && var.group_number == floor(var.group_number)
    error_message = "group_number must be an integer between 1 and 254."
  }
}

variable "owner" {
  description = "Owner value applied to the owner tag."
  type        = string
}

variable "environment" {
  description = "Environment value applied to the env tag."
  type        = string
  default     = "dev"
}

variable "vm_size" {
  description = "Azure VM SKU selected during the TP."
  type        = string
}

variable "admin_username" {
  description = "Linux administrator username for the web VMs."
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Local path to the SSH public key file used for VM authentication."
  type        = string
}

variable "allowed_ssh_ip" {
  description = "Public IPv4 address allowed to SSH to the jumpbox, in CIDR notation with /32."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.allowed_ssh_ip)) && endswith(var.allowed_ssh_ip, "/32")
    error_message = "allowed_ssh_ip must be a public IPv4 address in CIDR notation ending in /32."
  }
}

variable "alert_email" {
  description = "Email address that receives Azure Monitor CPU alert notifications."
  type        = string

  validation {
    condition     = can(regex("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$", var.alert_email))
    error_message = "alert_email must be a valid email address."
  }
}
