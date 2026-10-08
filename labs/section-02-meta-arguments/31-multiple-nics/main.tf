# Lab 31 (assignment) — one NIC per tier, using for_each.
# Shows deriving a map from a set with a `for` expression to compute CIDRs.

# locals: the tiers list that the computed for_each map is built from.
locals {
  # A LIST (not a set): the two-value `for` over a list gives i as the numeric
  # index, which we use to compute each tier's CIDR.
  tiers = ["web", "app", "data"]
}

# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = "rg-multi-nics"
  location = "eastus"
}

# Virtual network: one /16 address space that the computed /24 subnets fit into.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-multi-nics"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.160.0.0/16"]
}

# A `for` over the list produces a map: tier → "10.160.<i+1>.0/24".
# i is the numeric index, t the value. We build the CIDR per tier.
resource "azurerm_subnet" "this" {
  for_each             = { for i, t in local.tiers : t => "10.160.${i + 1}.0/24" }
  name                 = "snet-${each.key}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value]
}

# for_each over the subnets map → one NIC per tier, each in its matching subnet.
# each.value here is a subnet resource object (because we iterate the resource map).
resource "azurerm_network_interface" "this" {
  for_each            = azurerm_subnet.this
  name                = "nic-${each.key}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = each.value.id # the subnet's id
    private_ip_address_allocation = "Dynamic"
  }
}

# Output: keys() lists the for_each keys — one NIC name per tier.
output "nics" { value = keys(azurerm_network_interface.this) }
