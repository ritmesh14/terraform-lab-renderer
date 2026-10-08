# Lab 50 — dynamic blocks at TWO levels in one resource.
# An NSG with dynamic security_rule (from a list) AND a NIC with dynamic
# ip_configuration (from a list) — all from variables, no code changes to extend.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }

  }
}
# The azurerm provider is the bridge to Azure; it must be configured (features {}
# is the minimal required argument) before any azurerm_* resource can be planned.
provider "azurerm" {
  features {}
}

# Each entry → one security_rule block on the NSG.
# Inputs: the two lists the dynamic blocks iterate. One entry per object = one
# nested block generated — extend either list and re-apply.
variable "rules" {
  type = list(object({
    name     = string
    priority = number
    port     = number
  }))
  default = [
    { name = "Allow-SSH", priority = 200, port = 22 },
    { name = "Allow-HTTPS", priority = 210, port = 443 },
  ]
}

# Each entry → one ip_configuration block on the NIC (multiple IPs).
variable "ip_configs" {
  type = list(object({
    name      = string
    primary   = bool
    static_ip = string
  }))
  default = [
    { name = "ipconfig-1", primary = true, static_ip = "172.22.0.10" },
    { name = "ipconfig-2", primary = false, static_ip = "172.22.0.11" },
  ]
}

# locals: names + CIDRs (/20 VNet, /26 subnet — smaller blocks than earlier labs,
# they only have to nest).
locals {
  rg   = "rg-dynamic-multi"
  vnet = "172.22.0.0/20"
  snet = "172.22.0.0/26"
}

# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = local.rg
  location = "eastus"
}

# Virtual network + subnet: both dynamic-generated resources live here.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-dynamic-multi"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [local.vnet]
}

# Subnet: the /26 the NIC's dynamic ip_configurations attach to.
resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.snet]
}

# FIRST dynamic: security_rule blocks generated from var.rules.
resource "azurerm_network_security_group" "web" {
  name                = "nsg-dynamic-multi"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  dynamic "security_rule" {
    for_each = var.rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = tostring(security_rule.value.port)
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
}

# SECOND dynamic: ip_configuration blocks generated from var.ip_configs.
resource "azurerm_network_interface" "web" {
  name                = "nic-dynamic-multi"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  dynamic "ip_configuration" {
    for_each = var.ip_configs
    content {
      name                          = ip_configuration.value.name
      subnet_id                     = azurerm_subnet.web.id
      private_ip_address_allocation = "Static"
      private_ip_address            = ip_configuration.value.static_ip
      primary                       = ip_configuration.value.primary
    }
  }
}

# Outputs: rule names from the variable, and the NIC's list of private IPs
# (Azure returns one per ip_configuration — proof the dynamic blocks landed).
output "rule_names" { value = [for r in var.rules : r.name] }
# A NIC with multiple IPs exposes them as a list: private_ip_addresses.
output "nic_ips" { value = azurerm_network_interface.web.private_ip_addresses }
