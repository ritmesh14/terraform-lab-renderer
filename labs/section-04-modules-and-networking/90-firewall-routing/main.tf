# Lab 90 — route workload traffic THROUGH the Azure Firewall.
#  - azurerm_route_table with a route: 0.0.0.0/0 → next_hop_type = VirtualAppliance,
#    next_hop_in_ip_address = the firewall's private IP (from lab 89).
# This lab creates the route table only; associate it with the workload subnet
# (manually in the portal, or via azurerm_subnet_route_table_association) so
# the subnet's outbound traffic goes via the firewall.
variable "firewall_private_ip" { type = string }

# Resource group everything in this lab goes into.
resource "azurerm_resource_group" "this" {
  name     = "rg-fw-routing"
  location = "eastus"
}

# The UDR (user-defined route table): custom routing that overrides Azure's
# default system routes for every subnet it is associated with.
resource "azurerm_route_table" "this" {
  name                = "rt-fw"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  # Default route: EVERY destination (0.0.0.0/0) is sent to the firewall's
  # private IP. VirtualAppliance = a network virtual appliance (here: Azure Firewall).
  route {
    name                   = "to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_private_ip
  }
}

# Associate this id with the workload subnet (portal or a
# azurerm_subnet_route_table_association resource) to activate the routing.
output "route_table_id" { value = azurerm_route_table.this.id }
