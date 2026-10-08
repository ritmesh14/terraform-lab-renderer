# Lab 49 — for_each over a data block (discovery pattern).
# Point `rg_names` at resource groups that ALREADY exist in your subscription.
# Terraform then opens one data source per name — read-only, no changes.
# CAUTION: data sources read live Azure state; run in a sandbox subscription.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }

  }
}
# The azurerm provider is the bridge to Azure; it must be configured (features {}
# is the minimal required argument) before any azurerm_* resource can be planned.
provider "azurerm" {
  features {}
}

# The list data source `azurerm_resource_groups` was removed in azurerm 3.x,
# so discovery here is driven by the names you pass in. The data blocks below
# are still `for_each` over data — the pattern this lab teaches.
# Inputs: existing resource-group names to look up. An empty set (the default)
# means nothing is discovered and no data source is created.
variable "rg_names" {
  description = "Names of existing resource groups to discover."
  type        = set(string)
  default     = []
}

# locals: turns the set of names into a MAP (name => name). A set is valid for
# for_each already, but the explicit map keeps keys/values clear for beginners.
locals {
  # Build a map name -> id from the discovered list, for for_each.
  by_name = {
    for name in var.rg_names : name => name
  }
}

# One data source per name; each returns the live resource group's attributes.
data "azurerm_resource_group" "each" {
  for_each = local.by_name
  name     = each.key
}

# Outputs: how many groups were found, their names, and a for expression that
# collects the .id of every discovered data-source instance.
output "discovered_rg_count" { value = length(local.by_name) }
output "discovered_rg_names" { value = keys(local.by_name) }
output "discovered_rg_ids" { value = [for rg in data.azurerm_resource_group.each : rg.id] }