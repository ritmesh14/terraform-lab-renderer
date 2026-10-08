# ---------------------------------------------------------------------------
# Lab 07 — Local values (and shared tags)
# Builds: resource group "rg-foundation-eastus" + VNet "vnet-foundation",
# both tagged with a shared tags map.
# Teaches: locals for interpolation and one-place naming, plus merge() to build
# tag maps from a common base.
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

# locals are great for: building names, and for tags you repeat on every resource.
locals {
  region  = "eastus"
  project = "foundation"
  rg_name = "rg-${local.project}-${local.region}" # string interpolation builds the name

  # A common tag map shared by all resources. merge() combines maps; later labs
  # merge this with per-resource tags.
  common_tags = {
    project   = local.project
    managedby = "terraform"
    section   = "01-foundations"
  }
}

# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = local.rg_name
  location = local.region
  tags     = local.common_tags # apply the shared tags
}

# Virtual network. Its name is interpolated from a local, and its tags are the
# common tags merged with one resource-specific tag.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-${local.project}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.30.0.0/16"]
  # merge() combines the common tags with one extra tag specific to this resource.
  tags = merge(local.common_tags, { tier = "network" })
}

# Prints the merged tag map so you can check the result after apply.
output "tags" { value = azurerm_virtual_network.this.tags }
