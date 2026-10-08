# ---------------------------------------------------------------------------
# Lab 06 — Virtual Network with inline subnets
# Builds: resource group "rg-vnet-foundation" + VNet "vnet-foundation" containing
# subnets "snet-web" and "snet-app".
# Teaches: private IP space in Azure (CIDR blocks) and inline `subnet {}` blocks.
# ---------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }

  }
}

# The azurerm provider configures the Azure plugin. `features {}` is required
# even when empty. Credentials come from `az login` or the ARM_* env vars.
provider "azurerm" {
  features {}
}

# `locals {}` holds the names used below, so renaming means one edit.
locals {
  rg_name = "rg-vnet-foundation"
  region  = "eastus"
  vnet    = "vnet-foundation"
}

# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = local.rg_name
  location = local.region
}

# A Virtual Network (VNet) is your private IP space inside Azure. address_space is a
# LIST of CIDR blocks. Here we use one /16 (65k addresses).
resource "azurerm_virtual_network" "this" {
  name                = local.vnet
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.20.0.0/16"]

  # Subnets defined INSIDE the VNet block. This is the quick way, but it's less
  # flexible than defining each subnet as its own resource (see lab 12).
  subnet {
    name           = "snet-web"
    address_prefix = "10.20.1.0/24" # a subnet takes a slice of the VNet's space
  }

  subnet {
    name           = "snet-app"
    address_prefix = "10.20.2.0/24"
  }
}

# Outputs print the VNet's id (used by later labs/resources) and its name.
output "vnet_id" { value = azurerm_virtual_network.this.id }
# The VNet's human-readable name.
output "vnet_name" { value = azurerm_virtual_network.this.name }
