# Lab 84 — one VM per VNet (so we can test connectivity after peering in lab 85).
#  - hub: rg/VNet/subnet/NIC/VM in eastus (10.22.0.0/16).
#  - spoke: rg/VNet/subnet/NIC/VM in westus2 (10.23.0.0/16).
# After peering, the hub VM can ping the spoke VM's private IP.

# Root variable for both VMs' admin SSH key (kept out of CLI output).
variable "admin_ssh_key" {
  type      = string
  sensitive = true
}

# HUB stack: RG + VNet (10.22.0.0/16) + subnet + NIC + VM, in eastus.
resource "azurerm_resource_group" "hub" {
  name     = "rg-peer-hub"
  location = "eastus"
}
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-peer-hub"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = ["10.22.0.0/16"]
}
resource "azurerm_subnet" "hub" {
  name                 = "snet-hub"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.22.1.0/24"]
}
# Dynamic private IP — the hub VM's address (an output below) is what you ping.
resource "azurerm_network_interface" "hub" {
  name                = "nic-hub"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.hub.id
    private_ip_address_allocation = "Dynamic"
  }
}
# The hub-side test VM (no public IP — reach it via Azure Bastion or peering).
resource "azurerm_linux_virtual_machine" "hub" {
  name                  = "vm-hub"
  location              = azurerm_resource_group.hub.location
  resource_group_name   = azurerm_resource_group.hub.name
  size                  = "Standard_B1s"
  admin_username        = "azureadmin"
  network_interface_ids = [azurerm_network_interface.hub.id]
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

# SPOKE stack: a completely separate RG/VNet (10.23.0.0/16)/subnet/NIC/VM in westus2.
resource "azurerm_resource_group" "spoke" {
  name     = "rg-peer-spoke"
  location = "westus2"
}
resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-peer-spoke"
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  address_space       = ["10.23.0.0/16"]
}
resource "azurerm_subnet" "spoke" {
  name                 = "snet-spoke"
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = ["10.23.1.0/24"]
}
# Dynamic private IP — the spoke VM's address (an output below) is the ping target.
resource "azurerm_network_interface" "spoke" {
  name                = "nic-spoke"
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.spoke.id
    private_ip_address_allocation = "Dynamic"
  }
}
# The spoke-side test VM (no public IP — peering in lab 85 is what connects them).
resource "azurerm_linux_virtual_machine" "spoke" {
  name                  = "vm-spoke"
  location              = azurerm_resource_group.spoke.location
  resource_group_name   = azurerm_resource_group.spoke.name
  size                  = "Standard_B1s"
  admin_username        = "azureadmin"
  network_interface_ids = [azurerm_network_interface.spoke.id]
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

# The two private IPs you ping between once lab 85 has peered the VNets.
output "hub_private_ip" { value = azurerm_network_interface.hub.private_ip_address }
output "spoke_private_ip" { value = azurerm_network_interface.spoke.private_ip_address }
