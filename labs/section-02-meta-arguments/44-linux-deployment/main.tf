# RG + VNet + subnet + NSG (SSH allowed) + public IP + NIC.
# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = local.rg
  location = "eastus"
}

# Virtual network + subnet: the NIC's network.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-deploy"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.250.0.0/16"]
}

# Subnet: the /24 the NIC attaches to.
resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.250.1.0/24"]
}

# NSG allows SSH (22). Tighten source_address_prefix to your IP in prod.
resource "azurerm_network_security_group" "web" {
  name                = "nsg-deploy"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# A public IP so you can SSH in from the internet.
resource "azurerm_public_ip" "web" {
  name                = "pip-deploy"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# NIC bound to the subnet AND the public IP.
resource "azurerm_network_interface" "web" {
  name                = "nic-deploy"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web.id
  }
}

# The VM: Ubuntu 22.04 on a cheap burstable size, SSH key from locals.
resource "azurerm_linux_virtual_machine" "web" {
  name                  = "vm-deploy"
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
