# Lab 75 — a module creating a public IP + NIC. It consumes a subnet id produced
# by ANOTHER module (modules/vnet) → modules chain together.
# Builds: rg-vnet-modip, vnet-modip + subnet web, pip-nic-modip, nic-modip.
# Concept: module output → module input (wiring modules together).

# Terraform block: required CLI version + provider versions this config needs.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }

  }
}

# Provider block: configures azurerm. `features {}` is required (can stay empty).
provider "azurerm" {
  features {}
}

# First build the network (returns subnet ids).
module "network" {
  source          = "../../modules/vnet"
  name            = "vnet-modip"
  location        = "eastus"
  address_space   = ["10.12.0.0/16"]
  subnet_prefixes = ["10.12.1.0/24"]
  subnet_names    = ["web"]
}

# Then create a NIC in the first subnet, passing the RG name and subnet id.
module "nic" {
  source              = "../../modules/ip-nic"
  name                = "nic-modip"
  location            = "eastus"
  resource_group_name = "rg-vnet-modip"
  subnet_id           = module.network.subnet_ids[0]
}

output "nic_id" { value = module.nic.nic_id }
output "public_ip" { value = module.nic.public_ip }
