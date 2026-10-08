# Lab 42 — reading a local file with file() / fileexists().
# Teaches: fileexists() ? file() : fallback (the ternary operator), reading
# configuration from the filesystem at plan time, and the standard single-VM
# VNet/subnet/NIC stack.
# file() and filebase64() read a file from the lab folder at plan/apply time.
# Here we read a public SSH key from id_rsa.pub and feed it to the VM.

# locals: the SSH key, read from disk (or the fallback) — see the ternary below.
locals {
  # fileexists() guards against the file being absent (avoids a hard error).
  # If id_rsa.pub exists, read it; otherwise fall back to a placeholder.
  ssh_pubkey = fileexists("id_rsa.pub") ? file("id_rsa.pub") : "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCzc5yjPpF02BZc/k9D6S2pkKmBfZFksOBDaD3W/DvbJmN557CipWKC3nqw4NpRp8U25xD0T4RGOXSSRzneDT3zwZxEhqt4y3A9r39KwOCz0VKOalTZ5X1HPV9tgh+ljBjDluu812+UG0mAeYZ3HMWFuqypNFGRL5vxOEPSkmCYbxxOH/5hpIX3b4mBlq1EeSY+k1L3NQqiQ6byNU2xP69gLiT0EUbyrb4g4IuK/zGj7X+upJaVF7Dfgpqe8O70dRzgiIPAuTsqkkEFt+cAawUOMaNfDOhnjQktZBlMYpgWPhU7Dcn+ICyAoruzmXLH79PhttaCAyF0xNtUz7xXAn9v terraform-lab-placeholder"
}

# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = "rg-linux-readfile"
  location = "eastus"
}

# Virtual network + subnet: the single NIC's network.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-linux-readfile"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.230.0.0/16"]
}

# Subnet: the /24 the NIC attaches to.
resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.230.1.0/24"]
}

# NIC: connects the VM to the subnet (dynamic private IP inside 10.230.1.0/24).
resource "azurerm_network_interface" "web" {
  name                = "nic-readfile"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }
}

# admin_ssh_key uses the file contents read above.
resource "azurerm_linux_virtual_machine" "web" {
  name                  = "vm-readfile"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  size                  = "Standard_B1s"
  admin_username        = "azureadmin"
  network_interface_ids = [azurerm_network_interface.web.id]
  admin_ssh_key {
    username   = "azureadmin"
    public_key = local.ssh_pubkey
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
