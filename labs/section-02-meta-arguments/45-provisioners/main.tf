# Lab 45 — Provisioners (LAST RESORT).
# Provisioners run scripts at create/destroy time. They're not idempotent, not in
# `plan`, and fail the run if they error. Prefer custom_data/cloud-init. This lab
# shows a remote-exec over SSH just to demonstrate the mechanics.

# Sensitive inputs: TWO different halves of the same keypair. admin_public_key is
# what the VM trusts (the admin_ssh_key block); admin_private_key is what Terraform
# signs with when the provisioner SSHes in (the connection block). A public key can
# never stand in for a private key — they are separate variables on purpose.
variable "admin_public_key" {
  type      = string
  sensitive = true
}
variable "admin_private_key" {
  type      = string
  sensitive = true
}
# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = "rg-provisioner"
  location = "eastus"
}

# Virtual network + subnet: the NIC's network.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-provisioner"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.251.0.0/16"]
}

# Subnet: the /24 the NIC attaches to.
resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.251.1.0/24"]
}

# NSG with an SSH rule (needed so the provisioner's SSH connection can reach the
# VM) — but note it is never associated with the subnet, see README gotchas.
resource "azurerm_network_security_group" "web" {
  name                = "nsg-provisioner"
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

# Public IP: the provisioner's connection host is this VM's public IP.
resource "azurerm_public_ip" "web" {
  name                = "pip-provisioner"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# NIC: binds the subnet and the public IP to the VM.
resource "azurerm_network_interface" "web" {
  name                = "nic-provisioner"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web.id
  }
}

# The VM. Everything above is standard; the interesting part is the provisioner
# at the bottom of this block.
resource "azurerm_linux_virtual_machine" "web" {
  name                  = "vm-provisioner"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  size                  = "Standard_B1s"
  admin_username        = "azureadmin"
  network_interface_ids = [azurerm_network_interface.web.id]
  admin_ssh_key {
    username   = "azureadmin"
    public_key = var.admin_public_key
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

  # The provisioner runs ONCE at create time, over SSH, from the machine running
  # Terraform (not from inside Azure). A beginner would use a provisioner only for
  # steps nothing else can do — e.g. copying a local file, bootstrapping a config
  # manager, or cleanup on destroy — never for normal software installs.
  # `self` refers to the VM
  # resource, so self.public_ip_address is this VM's public IP.
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "cat /etc/os-release",
    ]

    connection {
      type        = "ssh"
      host        = self.public_ip_address
      user        = "azureadmin"
      private_key = var.admin_private_key
    }
  }
}

# Output: the SSH target — unknown during plan, assigned by Azure at apply.
output "public_ip" { value = azurerm_public_ip.web.ip_address }
