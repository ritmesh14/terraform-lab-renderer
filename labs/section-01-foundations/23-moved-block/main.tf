# ---------------------------------------------------------------------------
# Lab 23 — The `moved {}` block (refactoring addresses)
# Builds: resource group "rg-moved-block", VNet "vnet-moved" (172.16.0.0/20),
# subnet "snet-web" (/26), storage account "stmoved<suffix>".
# Teaches: renaming a resource address in code without destroy/create — the
# moved block rewrites the state address in place.
# ---------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# The azurerm provider configures the Azure plugin. `features {}` is required
# even when empty. Credentials come from `az login` or the ARM_* env vars.
provider "azurerm" {
  features {}
}

# `locals {}` holds names and CIDR blocks used below.
locals {
  rg   = "rg-moved-block"
  vnet = "172.16.0.0/20" # /20 = 4096 addresses (not the usual /16)
  snet = "172.16.0.0/26" # /26 = 64 addresses (not the usual /24)
}

# A stateful random string. Unlike md5(timestamp()) this value is SAVED in
# Terraform state, so it only changes when the resource is destroyed —
# every plan/apply is stable and nothing gets unexpectedly replaced.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = local.rg
  location = "eastus"
}

# VNet + subnet using the unusual CIDR sizes from locals.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-moved"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [local.vnet]
}

# The subnet carved from the VNet's /20 space.
resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.snet]
}

# The storage account at its NEW address (this).
resource "azurerm_storage_account" "this" {
  name                     = lower("stmoved${random_string.suffix.result}")
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# `moved {}` tells Terraform: anything previously managed as .legacy is now .this.
# Terraform updates the STATE address IN PLACE — no destroy/create of the real
# resource. Remove this block after everyone has applied the rename.
moved {
  from = azurerm_storage_account.legacy
  to   = azurerm_storage_account.this
}

# Prints the (renamed) storage account's name after apply.
output "storage_name" { value = azurerm_storage_account.this.name }
