# Lab 126 — `moved` and `removed` blocks (safe refactoring).
#  - moved {}: change a resource's ADDRESS without recreating it (Terraform rewrites
#    the state address in place).
#  - removed {}: drop a resource from Terraform's management WITHOUT deleting it in
#    Azure (it becomes unmanaged). Useful when you want Terraform to stop owning it.
# Standard terraform/provider setup. Note: the `removed` block below is a
# Terraform 1.7+ feature, so in practice you want >= 1.7 for this lab.
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
# The `provider` block configures the Azure plugin. `features {}` must be
# present (it can stay empty) in azurerm 3.x.
provider "azurerm" {
  features {}
}

# A stateful random string. Unlike md5(timestamp()) this value is SAVED in
# Terraform state, so it only changes when the resource is destroyed —
# every plan/apply is stable and nothing gets unexpectedly replaced.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Container for the resources below.
resource "azurerm_resource_group" "this" {
  name     = "rg-moved-removed"
  location = "eastus"
}

# Current (new) address of the storage account. In a real refactor you'd get
# here by renaming azurerm_storage_account.legacy -> .this in the config; the
# `moved` block below tells Terraform it is the SAME object, not a new one.
resource "azurerm_storage_account" "this" {
  name                     = lower("stmovedrm${random_string.suffix.result}")
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# A `moved` block = a state-address rewrite, not a resource change. Terraform
# relabels the state entry from .legacy to .this and the plan shows NO
# destroy/create. Bonus: a moved block whose `from` is not in state is simply
# ignored, so this block is harmless to run before any legacy apply.
moved {
  from = azurerm_storage_account.legacy
  to   = azurerm_storage_account.this
}

# A `removed` block takes a resource out of Terraform's management on the next
# apply WITHOUT deleting it in Azure ("forget", formerly `terraform state rm`).
# Gotcha: the address MUST exist in state — plan errors with "Removing
# resource block that is not present in state" otherwise, so first apply a
# config that actually creates azurerm_storage_account.orphan, then this block.
removed {
  from = azurerm_storage_account.orphan
}

output "storage_name" { value = azurerm_storage_account.this.name }
