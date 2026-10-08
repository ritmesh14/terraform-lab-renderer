# Module: RG + VNet + a parallel list of subnets.
# Inputs: name, location, address_space, subnet_prefixes, subnet_names.
# Outputs: vnet_id, subnet_ids.
# CONTRACT: pass the lists in → get the vnet id + a list of subnet ids back.

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

# --- INPUTS (what callers must pass in) ---

variable "name" {
  description = "Base name; the resource group becomes rg-<name>."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "address_space" {
  description = "VNet address space CIDR(s)."
  type        = list(string)
}

variable "subnet_prefixes" {
  description = "One CIDR per subnet, paired by index with subnet_names."
  type        = list(string)
}

variable "subnet_names" {
  description = "One name per subnet, paired by index with subnet_prefixes."
  type        = list(string)
}

# --- RESOURCES ---

# The RG is created BY the module (name = rg-<name>), so callers don't pass it.
resource "azurerm_resource_group" "this" {
  name     = "rg-${var.name}"
  location = var.location
}

resource "azurerm_virtual_network" "this" {
  name                = var.name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.address_space
}

# zipmap pairs each subnet name with its CIDR by index.
resource "azurerm_subnet" "this" {
  for_each = zipmap(var.subnet_names, var.subnet_prefixes)

  name                 = each.key
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value]
}

# --- OUTPUTS (what callers get back as module.<alias>.<output>) ---

output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

# A for-expression collects every subnet's id into one list, ordered by key.
output "subnet_ids" {
  value = [for s in azurerm_subnet.this : s.id]
}