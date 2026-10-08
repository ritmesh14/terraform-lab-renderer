# Module: full stack — RG → VNet → subnet → NSG → public IP → NIC → Linux VM.
# All names derive from name_prefix. custom_data (optional) is base64 cloud-init.
# CONTRACT: inputs name_prefix/location/admin_ssh_key/network CIDRs (+optional
# tags, custom_data) → outputs public_ip + vm_name.

# Terraform block: the module's own provider/version requirements.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }
  }
}

# --- INPUTS (what callers must pass in; tags/custom_data are optional) ---

variable "name_prefix" {
  description = "Drives every resource name (rg-, vnet-, subnet-, ...)."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "admin_ssh_key" {
  description = "SSH public key for the VM admin user."
  type        = string
  sensitive   = true
}

variable "vnet_address_space" {
  description = "VNet address space CIDR(s)."
  type        = list(string)
}

variable "subnet_prefix" {
  description = "CIDR for the single subnet."
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}

variable "custom_data" {
  description = "Base64-encoded cloud-init, or null for none."
  type        = string
  default     = null
}

# --- RESOURCES (the whole stack, all names derived from name_prefix) ---

resource "azurerm_resource_group" "this" {
  name     = "rg-${var.name_prefix}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.name_prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  name                 = "subnet-${var.name_prefix}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnet_prefix]
}

resource "azurerm_network_security_group" "this" {
  name                = "nsg-${var.name_prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  security_rule {
    # SSH open to the whole world (source_address_prefix = "*") — lab-only
    # convenience; a real deployment would restrict the source range.
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = azurerm_subnet.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_public_ip" "this" {
  name                = "pip-${var.name_prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "this" {
  name                = "nic-${var.name_prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

# The Linux VM: Standard_B2s, Ubuntu 22.04, SSH-key auth, optional cloud-init.
resource "azurerm_linux_virtual_machine" "this" {
  name                  = "vm-${var.name_prefix}"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  size                  = "Standard_B2s"
  network_interface_ids = [azurerm_network_interface.this.id]
  custom_data           = var.custom_data
  tags                  = var.tags

  admin_username = "azureadmin"
  admin_ssh_key {
    username   = "azureadmin"
    public_key = var.admin_ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# --- OUTPUTS (what callers get back as module.<alias>.<output>) ---

output "public_ip" {
  value = azurerm_public_ip.this.ip_address
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.this.name
}