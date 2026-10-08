# network.tf — RG + VNet + subnet + NIC (grouped by concern).
# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = local.rg
  location = "eastus"
}

# Virtual network + subnet: the NIC's network. File boundaries don't matter to
# Terraform — references like azurerm_resource_group.this work across files.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-structure"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.240.0.0/16"]
}

# Subnet: a /24 carved from the VNet's address space.
resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.240.1.0/24"]
}

# NIC: connects the VM (declared in vm.tf) to the subnet (declared here) —
# cross-file references are ordinary.
resource "azurerm_network_interface" "web" {
  name                = "nic-structure"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }
}
