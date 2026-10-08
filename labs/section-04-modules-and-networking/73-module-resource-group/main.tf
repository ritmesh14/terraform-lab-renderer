# Lab 73 — calling a local module.
# A module is a folder of .tf files you reuse. `source` points at it (here a
# relative path). Run `terraform init` to copy/link the module. Inputs go in the
# block body; outputs come back as module.name.output_name.
# Builds: rg-modulerg (resource group). Concept: the module block + module outputs.

# Terraform block: the config's own settings — required CLI version and which
# providers (from the public registry) this root module needs.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }

  }
}

# Provider block: configures azurerm (region etc. are set per-resource here).
# `features {}` is an empty settings block the azurerm provider requires.
provider "azurerm" {
  features {}
}

# Call the rg-only module (modules/rg-only). Pass its required inputs.
module "rg" {
  source   = "../../modules/rg-only"
  name     = "rg-modulerg"
  location = "eastus"
}

# Read the module's outputs with module.<name>.<output>.
output "rg_id" { value = module.rg.id }
output "rg_name" { value = module.rg.name }
