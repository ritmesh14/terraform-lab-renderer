# Lab 116 — Terraform workspaces (one config, several state files).
# terraform.workspace is the current workspace name (dev/prod/etc.).
#  - terraform workspace new dev / select dev
#  - names and SKU tiers derive from terraform.workspace.
# Best for SAME-SHAPE environments. For different shapes, use separate directories.
# The `terraform` block configures Terraform itself. No `backend` block here:
# with the default local backend, each workspace gets its own state file under
# terraform.tfstate.d/<workspace-name>/ — that isolation IS the feature.
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

# `terraform.workspace` is a built-in variable: the name of the currently
# selected workspace (`dev`, `prod`, ...; "default" if you never created one).
# Branching on it here is the classic "one config, N environments" pattern:
locals {
  env         = terraform.workspace
  rg          = "rg-ws-${local.env}"
  replication = local.env == "prod" ? "GRS" : "LRS"
}

# A stateful random string. Unlike md5(timestamp()) this value is SAVED in
# Terraform state, so it only changes when the resource is destroyed —
# every plan/apply is stable and nothing gets unexpectedly replaced.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Resource group named after the workspace: each workspace (state file) builds
# its own group, so dev and prod never touch each other's resources.
resource "azurerm_resource_group" "this" {
  name     = local.rg
  location = "eastus"
}

# Storage account named per workspace too (names must be 3-24 lowercase
# letters/digits, hence lower() and the compact prefix).
resource "azurerm_storage_account" "this" {
  name                     = lower("stws${local.env}${random_string.suffix.result}")
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = local.replication
  # A tag naming the workspace is cheap insurance in the portal.
  tags = { environment = local.env }
}

# Outputs echo which workspace/region settings this apply produced.
output "workspace" { value = local.env }
output "rg_name" { value = azurerm_resource_group.this.name }
output "replication" { value = azurerm_storage_account.this.account_replication_type }
