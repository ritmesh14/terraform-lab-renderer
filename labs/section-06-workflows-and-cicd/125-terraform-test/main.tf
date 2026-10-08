# Lab 125 — the built-in `terraform test` framework (.tftest.hcl).
# main.tf: a storage account whose tier is a variable.
# tests/main.tftest.hcl: `run` blocks with `command = plan` and `assert` checks:
#   - exactly one storage account in the plan,
#   - its tier is Standard.
# Run: terraform init && terraform test. (plan-only assertions need no real resources.)
# Standard terraform/provider setup — the tests below run a real `plan`
# against this config, so it needs real (installed) providers even though
# plan-only tests never create anything in Azure.
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
  name     = "rg-tftest"
  location = "eastus"
}

# The subject under test. Its `account_tier` comes from a variable, which is
# what makes the tier assertion in tests/main.tftest.hcl meaningful — a test
# can override the variable and check the config reacts correctly.
resource "azurerm_storage_account" "this" {
  name                     = lower("sttftest${random_string.suffix.result}")
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = var.tier
  account_replication_type = "LRS"
}

# Output so a test (or an apply-based test) can assert on the real value.
output "storage_name" { value = azurerm_storage_account.this.name }
