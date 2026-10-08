# Lab 74 — a module that creates RG + VNet + subnets. The caller passes the
# address space and parallel subnet name/prefix lists.
# Builds: rg-vnet-modvnet, vnet-modvnet, subnets web + app.
# Concept: passing lists into a module (the module contract's inputs).

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
  name            = "vnet-modvnet"
  location        = "eastus"
  address_space   = ["10.11.0.0/16"]
  subnet_prefixes = ["10.11.1.0/24", "10.11.2.0/24"] # one CIDR per subnet
  subnet_names    = ["web", "app"]                   # paired with prefixes by index
}

output "vnet_id" { value = module.network.vnet_id }
output "subnet_ids" { value = module.network.subnet_ids }
