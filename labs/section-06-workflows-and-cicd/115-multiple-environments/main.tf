# Lab 115 — multiple environments via tfvars only (same code).
# dev.tfvars and prod.tfvars set environment/location/replication differently.
#  - terraform apply -var-file=dev.tfvars
#  - terraform apply -var-file=prod.tfvars
# replication_type uses a ternary: GRS for prod, LRS otherwise.
# Variables are the knobs each environment turns. They have NO defaults here,
# so Terraform requires a value — supplied by dev.tfvars or prod.tfvars on the
# command line (-var-file=...). Same code, different inputs.
variable "environment" { type = string }
variable "location" { type = string }
# `default = {}` makes this optional: without it the tag would be empty.
variable "tags" {
  type    = map(string)
  default = {}
}
# A stateful random string. Unlike md5(timestamp()) this value is SAVED in
# Terraform state, so it only changes when the resource is destroyed —
# every plan/apply is stable and nothing gets unexpectedly replaced.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# The environment name is interpolated into the resource-group name, so dev
# and prod each get their own group (`rg-multi-env-dev` / `rg-multi-env-prod`).
resource "azurerm_resource_group" "this" {
  name     = "rg-multi-env-${var.environment}"
  location = var.location
  tags     = var.tags
}

# Storage account name must be 3-24 lowercase letters/digits only — hence
# lower() and a short prefix. Each environment gets a unique name.
resource "azurerm_storage_account" "this" {
  name                = lower("st${var.environment}${random_string.suffix.result}")
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  account_tier        = "Standard"
  # A ternary (condition ? a : b): prod gets geo-redundant storage (GRS),
  # every other environment gets the cheaper locally-redundant kind (LRS).
  # This is a common pattern for per-environment sizing/cost decisions.
  account_replication_type = var.environment == "prod" ? "GRS" : "LRS"
  tags                     = var.tags
}

# Outputs let you (or a pipeline) confirm which environment's settings landed.
output "rg_name" { value = azurerm_resource_group.this.name }
output "replication" { value = azurerm_storage_account.this.account_replication_type }
