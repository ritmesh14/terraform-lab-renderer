# Minimal module: creates ONLY a resource group and returns its id/name.
# CONTRACT: inputs name + location → outputs id + name.

# Terraform block: the module's own provider/version requirements.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }
  }
}

# --- INPUTS (what callers must pass in) ---

variable "name" {
  description = "Resource group name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

# --- RESOURCES (what the module creates) ---

# `this` is the conventional single-resource name inside a module.
resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location
}

# --- OUTPUTS (what callers get back as module.<alias>.<output>) ---

output "id" {
  value = azurerm_resource_group.this.id
}

output "name" {
  value = azurerm_resource_group.this.name
}