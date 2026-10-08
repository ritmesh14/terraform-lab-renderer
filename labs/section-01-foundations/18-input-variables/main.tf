# ---------------------------------------------------------------------------
# Lab 18 — Input variables (types, defaults, validation)
# Builds: resource group "rg-vars-foundation" + storage account whose name,
# region and tier all come from variables.
# Teaches: variable blocks — type, default, description — and `validation`
# blocks that reject bad input before plan.
# ---------------------------------------------------------------------------

# Variables make a configuration REUSABLE. Each variable can have a type, a
# default, a description, and validation rules. Override via tfvars, -var, or
# the TF_VAR_<name> environment variable.
variable "location" {
  type        = string
  default     = "eastus"
  description = "Azure region."
}

# name_prefix feeds the storage account name; the validation keeps it inside
# Azure's lowercase alphanumeric naming rules (length + charset).
variable "name_prefix" {
  type        = string
  default     = "stvar"
  description = "Lowercase prefix for the storage account (3-18 chars, alnum only)."

  # validation runs BEFORE plan. can() returns true if the expression succeeds.
  validation {
    condition     = can(regex("^[a-z0-9]{3,18}$", var.name_prefix))
    error_message = "name_prefix must be 3-18 lowercase alphanumerics."
  }
}

# An enum-style variable: the validation below restricts it to two choices.
variable "tier" {
  type        = string
  default     = "Standard"
  description = "Storage account tier."

  # contains() checks membership in a list — restrict to allowed values.
  validation {
    condition     = contains(["Standard", "Premium"], var.tier)
    error_message = "tier must be Standard or Premium."
  }
}

# `locals {}` combines variables with the random suffix into final names.
locals {
  rg = "rg-vars-foundation"
  st = "${var.name_prefix}${random_string.suffix.result}" # prefix + suffix
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
  name     = local.rg
  location = var.location
}

# Storage account — its name and tier are assembled from the variables above.
resource "azurerm_storage_account" "this" {
  name                     = local.st
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = var.tier # from the validated variable
  account_replication_type = "LRS"
}
