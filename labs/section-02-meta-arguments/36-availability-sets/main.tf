# Lab 36 — Availability Sets.
# Teaches: count on NICs and VMs, and pointing both counted VMs at ONE shared
# resource (the availability set id) so Azure spreads them across fault/update
# domains.
# An Availability Set spreads VMs across fault domains (separate hardware) and
# update domains (separate patch waves) within ONE datacenter → 99.95% SLA.

# Sensitive input: your SSH public key (no default → Terraform prompts, or pass
# with -var / tfvars). sensitive = true hides it in plan/apply output.
variable "admin_ssh_key" {
  type      = string
  sensitive = true
}
# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = "rg-availset"
  location = "eastus"
}

# platform_fault_domain_count = how many fault domains (usually 2 or 3).
# platform_update_domain_count = how many update domains (up to 20).
resource "azurerm_availability_set" "web" {
  name                         = "as-web"
  location                     = azurerm_resource_group.this.location
  resource_group_name          = azurerm_resource_group.this.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
}

# Virtual network + subnet: the network the two counted NICs attach to.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-availset"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.200.0.0/16"]
}

# Subnet: the /24 the counted NICs attach to.
resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.200.1.0/24"]
}

# Two NICs (one per VM), paired to the VMs below by count.index.
resource "azurerm_network_interface" "web" {
  count               = 2
  name                = "nic-as-${count.index}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Both VMs share the SAME availability_set_id → they land in different fault/update domains.
resource "azurerm_linux_virtual_machine" "web" {
  count                 = 2
  name                  = "vm-as-${count.index}"
  resource_group_name   = azurerm_resource_group.this.name
  location              = azurerm_resource_group.this.location
  size                  = "Standard_B1s"
  admin_username        = "azureadmin"
  network_interface_ids = [azurerm_network_interface.web[count.index].id]
  availability_set_id   = azurerm_availability_set.web.id
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
