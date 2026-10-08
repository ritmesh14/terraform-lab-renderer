# Lab 119 Part A — bootstrap the remote-state backend (run once).
# Creates the RG, storage account, and tfstate container that the app config (Part B)
# will point at. Outputs the names you pass to terraform init -backend-config=...

# NOTE: the bootstrap config itself still uses the DEFAULT local backend —
# chicken-and-egg: you need this apply's output values before anything can
# point at the Azure backend, and `backend` blocks can't reference resources.
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

# Names for the backend storage. Storage account names must be 3-24 lowercase
# letters/digits and globally unique in Azure, hence the random suffix.
locals {
  rg = "rg-tfstate"
  st = lower("sttfstate${random_string.suffix.result}")
}

# A stateful random string. Unlike md5(timestamp()) this value is SAVED in
# Terraform state, so it only changes when the resource is destroyed —
# every plan/apply is stable and nothing gets unexpectedly replaced.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Container for the backend storage account itself.
resource "azurerm_resource_group" "this" {
  name     = local.rg
  location = "eastus"
}

# The storage account that will hold every team's terraform.tfstate.
# The security settings matter: TLS 1.2 minimum, and nested items (blobs!)
# can never be made public — state files can contain secrets.
resource "azurerm_storage_account" "this" {
  name                            = local.st
  resource_group_name             = azurerm_resource_group.this.name
  location                        = azurerm_resource_group.this.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
}

# A blob container named "tfstate" inside that account — each Terraform config
# is one blob (app.tfstate, app.prod.tfstate, ...) inside this single container.
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

# Outputs feed straight into `terraform init -backend-config=...` in Part B.
output "resource_group_name" { value = azurerm_resource_group.this.name }
output "storage_account_name" { value = azurerm_storage_account.this.name }
output "container_name" { value = azurerm_storage_container.tfstate.name }
