# Lab 123 base — creates a storage account and outputs its name (to be read by consumer/).

# Standard terraform/provider setup. No `backend` block on purpose: the
# consumer lab reads this config's LOCAL terraform.tfstate file directly.
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
  name     = "rg-remote-base"
  location = "eastus"
}

# The storage account the consumer stack will reference — by NAME (an output),
# never by hand-copied resource id. Names must be 3-24 lowercase letters/digits.
resource "azurerm_storage_account" "this" {
  name                     = lower("stremote${random_string.suffix.result}")
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Outputs are the contract between stacks: whatever is exported here is
# readable by any config with `terraform_remote_state` on this state file.
output "storage_account_name" { value = azurerm_storage_account.this.name }
output "resource_group_name" { value = azurerm_resource_group.this.name }
