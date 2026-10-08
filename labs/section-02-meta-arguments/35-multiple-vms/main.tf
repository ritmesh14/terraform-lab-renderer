# Lab 35 — multiple VMs with count, each with a matching NIC by index.
# Teaches: two resources sharing one count so instances pair up by index, a
# required (no default) sensitive variable for the SSH key, and the nested blocks
# of a Linux VM (admin_ssh_key, os_disk, source_image_reference).
# count.index threads through dependent resources so NIC[i] matches VM[i].

# Input variables. vm_count has a default; admin_ssh_key has none, so Terraform
# prompts for it (or read it from tfvars). `sensitive = true` hides the value in
# plan/apply output — the key still reaches Azure, it is just not printed.
variable "vm_count" {
  type    = number
  default = 2
}
# The admin login name for every VM (same value is reused in the SSH key block).
variable "admin_username" {
  type    = string
  default = "azureadmin"
}
# The SSH public key injected into every VM; required (no default).
variable "admin_ssh_key" {
  type      = string
  sensitive = true
}
# locals: the resource-group name, defined once and reused below.
locals { rg = "rg-multi-vms" }

# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = local.rg
  location = "eastus"
}

# Virtual network + one subnet: the network the counted NICs attach to.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-multi-vms"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.190.0.0/16"]
}

# Subnet: the /24 the counted NICs attach to.
resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.190.1.0/24"]
}

# count NICs match the VM count. nic-vm-0, nic-vm-1, ...
resource "azurerm_network_interface" "web" {
  count               = var.vm_count
  name                = "nic-vm-${count.index}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }
}

# VM[i] uses NIC[i]: azurerm_network_interface.web[count.index].
resource "azurerm_linux_virtual_machine" "web" {
  count                 = var.vm_count
  name                  = "vm-web-${count.index}"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  size                  = "Standard_B1s"
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.web[count.index].id]

  # admin_ssh_key injects your public key so you can SSH in (no password).
  admin_ssh_key {
    username   = var.admin_username
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
