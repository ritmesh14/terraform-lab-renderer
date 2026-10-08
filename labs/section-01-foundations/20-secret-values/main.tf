# ---------------------------------------------------------------------------
# Lab 20 — Passing secret values
# Builds: resource group "rg-secret-foundation", VNet "vnet-secret", subnet
# "snet-web", NIC "nic-secret" and Windows VM "vm-secret-01".
# Teaches: sensitive variables — three ways to pass a secret (tfvars,
# TF_VAR_* env var, -var) — and what "masked in logs" does and doesn't cover.
# ---------------------------------------------------------------------------

# A sensitive variable is masked in plan/apply output. Pass it via tfvars
# (gitignored), -var, or the TF_VAR_admin_password environment variable.
variable "admin_password" {
  type      = string
  sensitive = true
}

# Not secret — just a defaulted username.
variable "admin_username" {
  type    = string
  default = "azureadmin"
}

# `locals {}` holds the resource group name used below.
locals {
  rg = "rg-secret-foundation"
}

# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = local.rg
  location = "eastus"
}

# Network stack for the VM (same shape as lab 17, minus the public IP/NSG).
resource "azurerm_virtual_network" "this" {
  name                = "vnet-secret"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.130.0.0/16"]
}

# The subnet the NIC (and VM) will live in.
resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.130.1.0/24"]
}

# The NIC connects the future VM to the subnet (private IP only).
resource "azurerm_network_interface" "web" {
  name                = "nic-secret"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }
}

# The password flows from the sensitive variable into the VM. It is never
# printed in plain text in the terminal because the variable is sensitive.
resource "azurerm_windows_virtual_machine" "web" {
  name                  = "vm-secret-01"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  network_interface_ids = [azurerm_network_interface.web.id]
  size                  = "Standard_B1s"
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
}
