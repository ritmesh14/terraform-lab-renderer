# Lab 30 — Multiple subnets with for_each over a map.
# Teaches: for_each with a map of key → value, the for expression that builds an
# output map, and VNet → subnet dependencies.
# The most-reused networking pattern: one VNet, several subnets from a map.

# locals: the map that drives the subnet fan-out (each key becomes a subnet).
locals {
  # Map of tier → CIDR. Each entry becomes one subnet.
  subnets = {
    web  = "10.150.1.0/24"
    app  = "10.150.2.0/24"
    data = "10.150.3.0/24"
    mgmt = "10.150.4.0/24"
  }
}

# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = "rg-multi-subnets"
  location = "eastus"
}

# Virtual network: one big /16 address space; the subnets below carve slices out
# of it. Referencing the resource group keeps the creation order correct.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-multi-subnets"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.150.0.0/16"]
}

# One subnet per map entry. each.key = "web", each.value = "10.150.1.0/24".
resource "azurerm_subnet" "this" {
  for_each             = local.subnets
  name                 = "snet-${each.key}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value]
}

# Output: a for expression that reshapes the for_each map into { "web": <id>, ... }.
# Read it as: "for each key k and subnet s in the map, produce k => s.id".
output "subnet_ids" {
  value = { for k, s in azurerm_subnet.this : k => s.id }
}
