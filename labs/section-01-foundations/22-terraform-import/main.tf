# ---------------------------------------------------------------------------
# Lab 22 — Importing an existing resource
# Builds: nothing! It ADOPTS a pre-existing storage account into Terraform
# state via the declarative `import {}` block.
# Teaches: import (CLI and block forms) and the Azure resource id format.
# ---------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0" # the declarative `import {}` block needs >= 1.5
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

# Read the current subscription so we can build the Azure resource id below.
data "azurerm_client_config" "current" {}

# These point at a storage account that ALREADY EXISTS in Azure (created outside
# Terraform, e.g. with the az CLI — see the README). We will adopt it, not create it.
variable "existing_sa_name" {
  type        = string
  description = "Storage account that already exists in Azure (created outside Terraform)."
}

variable "existing_rg_name" { type = string }

# `locals {}` builds the id string the import block needs.
locals {
  # Build the Azure resource id of the pre-existing storage account.
  # Format: /subscriptions/<sub>/resourceGroups/<rg>/providers/<provider>/<type>/<name>
  sa_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.existing_rg_name}/providers/Microsoft.Storage/storageAccounts/${var.existing_sa_name}"
}

# The declarative `import {}` block: on the next `terraform apply`, Terraform
# READS the existing resource and binds it to the address below — without
# creating or destroying anything. After that the resource is managed by Terraform.
import {
  to = azurerm_storage_account.adopted
  id = local.sa_id
}

# This block describes what the storage account SHOULD look like. After import,
# Terraform compares this to the real resource and shows any drift on the next plan.
resource "azurerm_storage_account" "adopted" {
  name                     = var.existing_sa_name
  resource_group_name      = var.existing_rg_name
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Prints the adopted account's id — matches local.sa_id after import.
output "adopted_id" { value = azurerm_storage_account.adopted.id }
