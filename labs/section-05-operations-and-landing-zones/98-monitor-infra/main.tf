# Lab 98 — infrastructure to be MONITORED.
# Builds: rg-monitor → vnet-monitor / snet-web → nic-monitor → vm-monitor (Ubuntu 22.04, B1s).
# Teaches: the Terraform "baseline" pattern (rg → vnet → subnet → NIC → VM) that every
# later lab in this section reuses, and that a monitoring story needs a real workload
# first (CPU metric → alert in lab 99).

# The VM admin's SSH public key. Passed in from terraform.tfvars (see terraform.tfvars.example)
# or with -var. `sensitive = true` hides it from `terraform output` and plan/apply logs.
variable "admin_ssh_key" {
  type      = string
  sensitive = true
}

# Resource group: the Azure "folder" every other resource in this lab is placed into.
resource "azurerm_resource_group" "this" {
  name     = "rg-monitor"
  location = "eastus"
}

# Virtual network: the private IP space for the VM. /16 is the whole range; a subnet carves it up.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-monitor"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.34.0.0/16"]
}

# Subnet: where the VM's NIC lives (10.34.1.0/24 out of the /16 above).
resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.34.1.0/24"]
}

# Network interface: the VM's virtual NIC, attached to the subnet. Azure assigns a private
# IP dynamically ("Dynamic" = leased from the subnet, can change on stop/deallocate).
resource "azurerm_network_interface" "vm" {
  name                = "nic-monitor"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Linux VM: the workload we will monitor in later labs. Standard_B1s is the cheapest
# burstable size — fine for generating a CPU metric, not for real work.
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "vm-monitor"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  size                  = "Standard_B1s"
  admin_username        = "azureadmin"
  network_interface_ids = [azurerm_network_interface.vm.id]
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

# Output: the VM's full Azure resource ID, so lab 99 can reference it
# (metric alerts attach to a specific resource ID).
output "vm_id" { value = azurerm_linux_virtual_machine.vm.id }
