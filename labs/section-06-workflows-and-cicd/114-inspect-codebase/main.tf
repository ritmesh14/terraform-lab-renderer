# Lab 114 — inspect a code base before refactoring.
# A tiny storage account you'll study. Try: terraform plan (see the diff preview),
# terraform graph | dot -Tsvg > graph.svg (visualize the dependency graph).
# `terraform graph` outputs DOT; pipe it to Graphviz to render.
# The `terraform` block configures Terraform itself, not Azure.
# - required_version: refuse to run on Terraform older than 1.5 (the version
#   this course assumes — e.g. the `terraform test` framework needs >= 1.5).
# - required_providers: which plugins (providers) to download during
#   `terraform init`, pinned with `~> 3.70` = "3.x, at least 3.70".
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
# The `provider` block configures the plugin that talks to Azure.
# `features {}` is an empty (but mandatory in azurerm 3.x) settings block —
# nothing is enabled, it just has to be present.
provider "azurerm" {
  features {}
}

# `locals` are named expressions — like variables, but computed inside this
# configuration instead of passed in. Reference them as `local.<name>`.
locals {
  region  = "eastus"
  rg_name = "rg-inspect"
  # Storage account names must be 3-24 lowercase letters/digits only, so the
  # random suffix is lowercased and the name has no dashes. `${...}` inside a
  # string is interpolation: "insert the value of this expression here".
  st_name = lower("stinspect${random_string.suffix.result}")
}

# A stateful random string. Unlike md5(timestamp()) this value is SAVED in
# Terraform state, so it only changes when the resource is destroyed —
# every plan/apply is stable and nothing gets unexpectedly replaced.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# A resource group is a folder-like container in Azure that everything else
# in this configuration lives inside (referenced below by `.name`/`.location`).
resource "azurerm_resource_group" "this" {
  name     = local.rg_name
  location = local.region
}

# A general-purpose storage account (blob containers, files, queues).
# Its attributes reference the resource group above — that reference is what
# `terraform graph` draws as a dependency arrow.
resource "azurerm_storage_account" "this" {
  name                     = local.st_name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# An `output` prints a value after apply (and shows it in `terraform output`),
# so child modules or pipelines can consume it.
output "storage_name" { value = azurerm_storage_account.this.name }
