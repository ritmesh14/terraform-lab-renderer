# Lab 86 — backend VMs for an Application Gateway (the pool lab 87 will use).
#  - VNet (10.26.0.0/16) with an appgw subnet and a backends subnet.
#  - 2 backend VMs running nginx (cloud-init) in the backends subnet.
# Outputs the backend private IPs and the appgw subnet id, consumed by lab 87.

# Root variable for the backend VMs' admin SSH key (kept out of CLI output).
variable "admin_ssh_key" {
  type      = string
  sensitive = true
}

# Locals: named expressions computed once per run (not stored in state).
locals {
  cloud_init = <<-EOT
    #cloud-config
    package_update: true
    packages: [nginx]
    runcmd:
      - systemctl enable --now nginx
      - echo "<h1>app-gw backend $(hostname)</h1>" > /var/www/html/index.html
  EOT
}

resource "azurerm_resource_group" "this" {
  name     = "rg-appgw"
  location = "eastus"
}

# The VNet holding both the (future) gateway and the backends.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-appgw"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.26.0.0/16"]
}

# Dedicated subnet for the Application Gateway (an App Gateway MUST have its
# own subnet — nothing else can share it; lab 87 deploys the gateway there).
resource "azurerm_subnet" "appgw" {
  name                 = "snet-appgw"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.26.1.0/24"]
}

# Subnet for the backend VMs (the gateway proxies requests to IPs here).
resource "azurerm_subnet" "backends" {
  name                 = "snet-backends"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.26.2.0/24"]
}

# 2 backend NICs — private IPs only; the gateway (lab 87) is their only front door.
resource "azurerm_network_interface" "backend" {
  count               = 2
  name                = "nic-appgw-be-${count.index}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.backends.id
    private_ip_address_allocation = "Dynamic"
  }
}

# 2 nginx VMs serving a hostname-stamped page so you can see which backend answered.
resource "azurerm_linux_virtual_machine" "backend" {
  count                 = 2
  name                  = "vm-appgw-be-${count.index}"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  size                  = "Standard_B1s"
  admin_username        = "azureadmin"
  network_interface_ids = [azurerm_network_interface.backend[count.index].id]
  custom_data           = base64encode(local.cloud_init)
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

# Outputs consumed by lab 87: NIC ids, the backend private IPs (→ backend pool),
# the appgw subnet id (→ gateway_ip_configuration) and the vnet id.
output "backend_ids" { value = azurerm_network_interface.backend[*].id }
output "backend_ips" { value = azurerm_network_interface.backend[*].private_ip_address }
output "appgw_subnet_id" { value = azurerm_subnet.appgw.id }
output "vnet_id" { value = azurerm_virtual_network.this.id }
