# ---------------------------------------------------------------------------
# Lab 04 — Named value references (local, var, resource refs)
# Builds: resource group "rg-refs-foundation" + storage account "stlogs<hash>".
# Teaches: the three reference families — local.x, var.x, and resource refs —
# so you never hardcode the same value twice.
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

# This lab shows the three reference families used everywhere in Terraform:
#   - local reference : local.<name>
#   - variable ref   : var.<name>
#   - resource ref   : azurerm_<type>.<localname>.<attribute>

locals {
  rg_name = "rg-refs-foundation" # LOCAL value, used below as local.rg_name
}

# An input variable. Defaulted here, but you can override it with -var or tfvars.
variable "location" {
  type    = string
  default = "eastus"
}

# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "core" {
  name     = local.rg_name # local reference
  location = var.location  # variable reference
}

# Storage account — every attribute here is a REFERENCE, not a repeated literal.
resource "azurerm_storage_account" "logs" {
  # md5(...) returns a hash; substr(...) takes the first 6 chars → a short suffix.
  name                     = lower("stlogs${substr(md5(azurerm_resource_group.core.id), 0, 6)}")
  resource_group_name      = azurerm_resource_group.core.name     # resource reference
  location                 = azurerm_resource_group.core.location # resource reference
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Outputs print the created names so you can verify them in the Azure portal.
output "rg_name" { value = azurerm_resource_group.core.name }
# The computed storage account name (prefix + hash suffix).
output "st_name" { value = azurerm_storage_account.logs.name }
