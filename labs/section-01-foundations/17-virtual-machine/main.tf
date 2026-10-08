# ---------------------------------------------------------------------------
# Lab 17 — Azure Virtual Machine
# Builds the full VM stack: resource group "rg-vm-foundation", VNet "vnet-vm",
# subnet "snet-web", NSG "nsg-vm" (RDP), public IP "pip-vm-01", NIC "nic-vm-01",
# Windows VM "vm-web-01".
# Teaches: wiring every earlier lab's resource into one dependency chain, plus
# sensitive input variables and source_image_reference.
# ---------------------------------------------------------------------------

# Variables for the admin account. The password is sensitive — it is masked in
# plan/apply output. Supply it via terraform.tfvars (gitignored) or -var.
variable "admin_username" {
  type    = string
  default = "azureadmin"
}

# `sensitive = true` hides the value from plan/apply logs (it still lives in
# state). No default — Terraform will ask for it if tfvars doesn't supply one.
variable "admin_password" {
  type      = string
  sensitive = true
}

# `locals {}` holds the names used below, so renaming means one edit.
locals {
  rg     = "rg-vm-foundation"
  region = "eastus"
}

# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = local.rg
  location = local.region
}

# The network stack the VM will attach to.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-vm"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.120.0.0/16"]
}

# The subnet the VM's NIC will live in.
resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.120.1.0/24"]
}

# NSG allowing RDP so we can log in to the Windows VM (tighten source in prod).
resource "azurerm_network_security_group" "web" {
  name                = "nsg-vm"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  security_rule {
    name                       = "Allow-RDP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# A static public IP so the VM address doesn't change on stop/start.
resource "azurerm_public_ip" "web" {
  name                = "pip-vm-01"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# The NIC ties the VM to the subnet AND to the public IP (for inbound access).
resource "azurerm_network_interface" "web" {
  name                = "nic-vm-01"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  ip_configuration {
    name                          = "ipconfig-vm"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web.id # gives the NIC a public IP
  }
}

# A Windows VM. network_interface_ids binds it to the NIC above. The OS disk
# and image are chosen via source_image_reference. admin_password comes from
# the sensitive variable — never hard-code it.
resource "azurerm_windows_virtual_machine" "web" {
  name                  = "vm-web-01"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  network_interface_ids = [azurerm_network_interface.web.id]
  size                  = "Standard_B1s" # small, cheap VM size
  admin_username        = var.admin_username
  admin_password        = var.admin_password

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS" # disk type for the OS disk
  }

  # The marketplace image to use. These four fields together identify it.
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
}

# The address to RDP to after apply — this is what the NSG rule allows traffic to.
output "public_ip" { value = azurerm_public_ip.web.ip_address }
