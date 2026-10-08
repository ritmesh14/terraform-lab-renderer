# ---------------------------------------------------------------------------
# Lab 05 — Explicit ordering with depends_on
# Builds: resource group "rg-depends-foundation", storage account "stdep<suffix>",
# container "data" inside it.
# Teaches: Terraform infers order from references; depends_on forces order when
# there is no reference — and why real references are preferred.
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

# `locals {}` holds derived values reused by the resources below.
locals {
  rg_name = "rg-depends-foundation"
  # lower() keeps the name lowercase; the random suffix makes it globally unique.
  st_name = lower("stdep${random_string.suffix.result}")
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
  name     = local.rg_name
  location = "eastus"
}

# Storage account. Referencing the RG's name/location creates an implicit
# dependency — Terraform always builds the RG before this account.
resource "azurerm_storage_account" "this" {
  name                     = local.st_name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# The container below only references the storage account's NAME as a plain string,
# so Terraform does NOT automatically know the account must exist first.
# `depends_on` makes the order explicit (use sparingly — prefer a real reference).
resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = local.st_name
  container_access_type = "private"

  depends_on = [azurerm_storage_account.this]
}
