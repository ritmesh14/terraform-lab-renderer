# Lab 113 — a VM with a system-assigned managed identity + least-privilege RBAC.
#  - identity { type = "SystemAssigned" } gives the VM an Azure identity (no secret).
#  - azurerm_role_assignment grants that identity ONLY "Storage Blob Data Reader" on
#    ONE storage account. From inside the VM you can read blobs using Azure RBAC —
#    no SAS, no key. That's least privilege.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
provider "azurerm" {
  features {}
}

# SSH key for the VM admin login (from terraform.tfvars.example). Hidden from logs.
variable "admin_ssh_key" {
  type      = string
  sensitive = true
}
# A stateful random string. Unlike md5(timestamp()) this value is SAVED in
# Terraform state, so it only changes when the resource is destroyed —
# every plan/apply is stable and nothing gets unexpectedly replaced.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Everything for this lab in one RG.
resource "azurerm_resource_group" "this" {
  name     = "rg-vm-mi"
  location = "eastus"
}

# A storage account + container the VM will be allowed to read.
resource "azurerm_storage_account" "this" {
  # lower() + suffix: storage names must be globally unique, lowercase, 3-24 chars.
  name                     = lower("stvmi${random_string.suffix.result}")
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# A private blob container: without the RBAC grant below, nothing can read it.
resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

# Networking for the VM.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-vm-mi"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["172.27.0.0/20"]
}

resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["172.27.0.0/26"]
}

# The VM's NIC, attached to the subnet (dynamic private IP).
resource "azurerm_network_interface" "vm" {
  name                = "nic-vm-mi"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }
}

# VM with a system-assigned managed identity.
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "vm-mi"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  size                  = "Standard_B1s"
  admin_username        = "azureadmin"
  network_interface_ids = [azurerm_network_interface.vm.id]
  admin_ssh_key {
    username   = "azureadmin"
    public_key = var.admin_ssh_key
  }
  identity { type = "SystemAssigned" }
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

# Grant the VM's identity ONLY blob-reader on this one account. principal_id comes
# from identity[0] — the identity block is a list, and SystemAssigned puts one entry
# in it whose principal_id is the Azure AD service principal Azure created for the VM.
resource "azurerm_role_assignment" "vm_blob_reader" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_linux_virtual_machine.vm.identity[0].principal_id
}

# Outputs: the VM's identity principal (for portal IAM checks) and storage name (for az CLI).
output "vm_principal_id" { value = azurerm_linux_virtual_machine.vm.identity[0].principal_id }
output "storage_name" { value = azurerm_storage_account.this.name }
