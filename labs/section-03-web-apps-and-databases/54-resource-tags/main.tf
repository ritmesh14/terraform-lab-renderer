# Lab 54 — Resource tags.
# Tags drive cost reporting, billing, and automation. Standardize them in locals
# and spread them with merge(). Changing var.environment retags everything.

# An input with a default. Change it (e.g. "prod") and every tagged resource
# gets retagged on the next apply.
variable "environment" {
  type    = string
  default = "dev"
}
locals {
  # Common tags reused on every resource.
  common_tags = {
    environment = var.environment
    managedby   = "terraform"
    costcenter  = "cc-100"
  }
}

# A stateful random string. Unlike md5(timestamp()) this value is SAVED in
# Terraform state, so it only changes when the resource is destroyed —
# every plan/apply is stable and nothing gets unexpectedly replaced.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# A resource group is Azure's folder: everything this lab creates lives here.
resource "azurerm_resource_group" "this" {
  name     = "rg-tags-${var.environment}"
  location = "eastus"
  tags     = local.common_tags
}

resource "azurerm_storage_account" "this" {
  name                     = lower("sttags${var.environment}${random_string.suffix.result}")
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  # merge() combines common tags with one resource-specific tag.
  tags = merge(local.common_tags, { tier = "storage" })
}

# Outputs print values after apply — here you can verify the tags landed.
output "rg_tags" { value = azurerm_resource_group.this.tags }
output "st_tags" { value = azurerm_storage_account.this.tags }
