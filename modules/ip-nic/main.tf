# Module: a static public IP + a NIC that consumes a subnet id from another
# module (chained modules).
# CONTRACT: inputs name, location, resource_group_name, subnet_id → outputs
# nic_id + public_ip. Note it does NOT create the subnet — the caller provides its id.

# Terraform block: the module's own provider/version requirements.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }
  }
}

# --- INPUTS (what callers must pass in) ---

variable "name" {
  description = "NIC name; the public IP becomes pip-<name>."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Existing resource group to deploy into."
  type        = string
}

variable "subnet_id" {
  description = "Subnet the NIC attaches to."
  type        = string
}

# --- RESOURCES ---

# Static (Standard SKU) public IP so the address survives restarts.
resource "azurerm_public_ip" "this" {
  name                = "pip-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# The NIC wires the public IP into the caller's subnet (var.subnet_id).
resource "azurerm_network_interface" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

# --- OUTPUTS (what callers get back as module.<alias>.<output>) ---

output "nic_id" {
  value = azurerm_network_interface.this.id
}

# The assigned public address (known only after apply).
output "public_ip" {
  value = azurerm_public_ip.this.ip_address
}