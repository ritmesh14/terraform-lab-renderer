# ---------------------------------------------------------------------------
# Lab 21 — Adding a data disk
# Builds: resource group "rg-disk-foundation", VM "vm-disk-01" (plus VNet/
# subnet/NIC) and a 32 GB managed data disk "disk-data-01" attached to it.
# Teaches: azurerm_managed_disk + azurerm_virtual_machine_data_disk_attachment,
# the OS disk vs data disk distinction, and LUNs.
# ---------------------------------------------------------------------------

# Same sensitive-password pattern as labs 17 and 20.
variable "admin_password" {
  type      = string
  sensitive = true
}

# `locals {}` holds the resource group name used below.
locals {
  rg = "rg-disk-foundation"
}

# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = local.rg
  location = "eastus"
}

# Network stack for the VM (unchanged from earlier labs).
resource "azurerm_virtual_network" "this" {
  name                = "vnet-disk"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.140.0.0/16"]
}

# The subnet the NIC (and VM) will live in.
resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.140.1.0/24"]
}

# The NIC connects the future VM to the subnet (private IP only).
resource "azurerm_network_interface" "web" {
  name                = "nic-disk"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }
}

# The OS disk holds Windows itself. A DATA disk is separate storage for your
# app data — it can be detached and re-attached to another VM later.
resource "azurerm_windows_virtual_machine" "web" {
  name                  = "vm-disk-01"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  network_interface_ids = [azurerm_network_interface.web.id]
  size                  = "Standard_B1s"
  admin_username        = "azureadmin"
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

# A managed disk: create_option = "Empty" makes a blank data disk.
resource "azurerm_managed_disk" "data" {
  name                 = "disk-data-01"
  location             = azurerm_resource_group.this.location
  resource_group_name  = azurerm_resource_group.this.name
  storage_account_type = "StandardSSD_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32
}

# Attach the disk to the VM. `lun` is the Logical Unit Number (0-63) that
# identifies the disk to the guest OS. Caching policy affects perf.
# NOTE: the attachment is a SEPARATE resource on purpose — changing
# `create_option` or disk size only touches the disk, and re-attaching to a
# new VM only touches the attachment.
resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  managed_disk_id    = azurerm_managed_disk.data.id
  virtual_machine_id = azurerm_windows_virtual_machine.web.id
  lun                = 0
  caching            = "ReadWrite"
}
