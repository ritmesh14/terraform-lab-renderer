# ---------------------------------------------------------------------------
# Lab 24 — templatefile() (advanced)
# Builds: resource group "rg-templatefile", VNet "vnet-templatefile" (/20),
# subnet "snet-web" (/26), NIC "nic-templatefile" and Linux VM "vm-templatefile"
# bootstrapped with cloud-init.
# Teaches: templatefile() to render cloud-init.tpl, base64encode + custom_data,
# and SSH-key auth for a Linux VM.
# ---------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }

  }
}

# The azurerm provider configures the Azure plugin. `features {}` is required
# even when empty. Credentials come from `az login` or the ARM_* env vars.
provider "azurerm" {
  features {}
}

# Your SSH public key, passed in via tfvars — no password is used on this VM.
variable "admin_ssh_key" {
  type      = string
  sensitive = true
}
# `locals {}` holds names/CIDRs plus the rendered template text (below).
locals {
  rg   = "rg-templatefile"
  vnet = "172.17.0.0/20"
  snet = "172.17.0.0/26"

  # templatefile(PATH, VARS) renders a file as a Terraform template, substituting
  # the vars map. The template can use %{ for %} and ${ } just like interpolation.
  # Keep big scripts OUT of .tf this way — cleaner and reusable.
  rendered = templatefile("${path.module}/cloud-init.tpl", {
    hostname = "web-templatefile"
    packages = ["nginx", "curl"]
  })
}

# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = local.rg
  location = "eastus"
}

# The network stack the Linux VM will attach to.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-templatefile"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [local.vnet]
}

# The subnet the NIC (and VM) will live in.
resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.snet]
}

# The NIC connects the VM to the subnet (private IP only).
resource "azurerm_network_interface" "web" {
  name                = "nic-templatefile"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }
}

# custom_data runs cloud-init on first boot. It MUST be base64-encoded; the
# VM decodes it. Here we feed the rendered template.
resource "azurerm_linux_virtual_machine" "web" {
  name                  = "vm-templatefile"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  size                  = "Standard_B1s"
  admin_username        = "azureadmin"
  network_interface_ids = [azurerm_network_interface.web.id]
  custom_data           = base64encode(local.rendered)
  admin_ssh_key {
    username   = "azureadmin"
    public_key = var.admin_ssh_key
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# Prints the first 120 chars of the rendered template so you can check the
# substitution worked without printing the whole cloud-init file.
output "rendered_preview" { value = substr(local.rendered, 0, 120) }
