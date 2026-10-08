# Lab 76 — a module that builds an NSG from a list of allowed ports (dynamic
# blocks inside the module) and associates it with a given subnet.
# Builds: rg-vnet-modnsg, vnet-modnsg + subnet web, nsg-modnsg (+3 Allow rules).
# Concept: handing data into a module and letting IT build the per-item blocks.

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

module "network" {
  source          = "../../modules/vnet"
  name            = "vnet-modnsg"
  location        = "eastus"
  address_space   = ["10.13.0.0/16"]
  subnet_prefixes = ["10.13.1.0/24"]
  subnet_names    = ["web"]
}

module "nsg" {
  source              = "../../modules/nsg"
  name                = "nsg-modnsg"
  location            = "eastus"
  resource_group_name = "rg-vnet-modnsg"
  allowed_ports       = [22, 80, 443] # the module turns each into an Allow rule
  subnet_id           = module.network.subnet_ids[0]
}

output "nsg_id" { value = module.nsg.nsg_id }
