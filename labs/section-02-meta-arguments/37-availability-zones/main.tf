# Lab 37 — Availability Zones.
# Teaches: count sized by length(local.zones) and count.index used as a lookup
# into the zones list (local.zones[count.index]) to give each VM its own zone.
# Zones are physically separate datacenters with independent power. Pinning a VM
# to a zone counts toward the 99.99% VM SLA when premium/ultra disks are used and
# the VMs span 2+ zones (with Standard SSD storage this lab alone is not SLA-qualifying).
# Here 3 VMs, one per zone (1, 2, 3).

# Sensitive input: your SSH public key (no default → Terraform prompts, or pass
# with -var / tfvars). sensitive = true hides it in plan/apply output.
variable "admin_ssh_key" {
  type      = string
  sensitive = true
}
# locals: the zone list that sizes count and names/pins each VM.
locals {
  zones = [1, 2, 3] # one VM per zone
}

# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = "rg-availzones"
  location = "eastus" # zones need a region that supports them
}

# Virtual network + subnet: the network all three counted NICs attach to.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-availzones"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.210.0.0/16"]
}

# Subnet: the /24 the counted NICs attach to.
resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.210.1.0/24"]
}

# One NIC per VM; count is driven by the length of the zones list, so adding a
# zone to the list scales NICs and VMs together.
resource "azurerm_network_interface" "web" {
  count               = length(local.zones)
  name                = "nic-az-${count.index}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }
}

# zone = tostring(1/2/3) pins the VM to that zone. VM names reflect the zone.
resource "azurerm_linux_virtual_machine" "web" {
  count                 = length(local.zones)
  name                  = "vm-az-${local.zones[count.index]}"
  resource_group_name   = azurerm_resource_group.this.name
  location              = azurerm_resource_group.this.location
  zone                  = tostring(local.zones[count.index])
  size                  = "Standard_B1s"
  admin_username        = "azureadmin"
  network_interface_ids = [azurerm_network_interface.web[count.index].id]
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
