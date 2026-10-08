# ---------------------------------------------------------------------------
# Lab 11 — Maps for subnets (assignment): variable-driven subnet layout
# Builds: resource group "rg-subnetmap-foundation", VNet "vnet-subnetmap" and
# one subnet per entry of the `subnets` variable (values come from terraform.tfvars).
# Teaches: map(object({...})) input variables + for_each — the production
# pattern for "same code, different shapes per environment".
# ---------------------------------------------------------------------------

# A VARIABLE typed as map(object(...)) lets callers pass a whole structure.
# This is the production pattern: same code, different shapes per environment.
variable "location" {
  type    = string
  default = "eastus"
}

# map(object({...})) means every key maps to an object with EXACTLY these two
# fields. terraform.tfvars must match this shape or Terraform rejects the value.
variable "subnets" {
  type = map(object({
    prefix = string
    nsg    = bool
  }))
  description = "Subnet definitions keyed by role."
}

# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = "rg-subnetmap-foundation"
  location = var.location
}

# The VNet the generated subnets live in.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-subnetmap"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.70.0.0/16"]
}

# One subnet per entry in the var.subnets map (values come from terraform.tfvars).
resource "azurerm_subnet" "this" {
  for_each             = var.subnets
  name                 = "snet-${each.key}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value.prefix]
}
