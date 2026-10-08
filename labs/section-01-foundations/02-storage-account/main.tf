# ---------------------------------------------------------------------------
# Lab 02 — Azure Storage Account (your first resource)
# Builds: resource group "rg-storage-foundation" + storage account
# "stfoundation<suffix>" (Standard, LRS).
# Teaches: resource blocks, locals, and a stateful random name suffix.
# ---------------------------------------------------------------------------

# `locals {}` holds DERIVED values — names we compute once and reuse. Using locals
# keeps the resource blocks below short and gives us one place to change a name.
locals {
  region  = "eastus"                # the Azure region to deploy into
  rg_name = "rg-storage-foundation" # the resource group name

  # Storage account names must be GLOBALLY unique (all of Azure), 3-24 chars,
  # lowercase + numbers only. We append a short random suffix (from the
  # random_string resource below) so the name is unique and won't collide.
  suffix  = random_string.suffix.result
  st_name = lower("stfoundation${local.suffix}")
}

# A resource group is a logical container for resources. Almost every Azure config
# starts by creating one. `azurerm_resource_group` is the resource TYPE; "this" is
# the LOCAL NAME we use to reference it elsewhere (e.g. azurerm_resource_group.this.id).
# A stateful random string. Unlike md5(timestamp()) this value is SAVED in
# Terraform state, so it only changes when the resource is destroyed —
# every plan/apply is stable and nothing gets unexpectedly replaced.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Resource group: the container that groups all resources for this lab in Azure.
# It comes first because every resource below needs its name and location.
resource "azurerm_resource_group" "this" {
  name     = local.rg_name # from locals above
  location = local.region
}

# A storage account. We reference the resource group's name/location so Terraform
# knows the dependency (it will create the RG before the storage account).
resource "azurerm_storage_account" "this" {
  name                            = local.st_name
  resource_group_name             = azurerm_resource_group.this.name # reference another resource
  location                        = azurerm_resource_group.this.location
  account_tier                    = "Standard" # Standard = disk-based, cheaper than Premium
  account_replication_type        = "LRS"      # Locally-redundant: 3 copies in one datacenter
  min_tls_version                 = "TLS1_2"   # enforce modern TLS for security
  allow_nested_items_to_be_public = false      # blobs are private by default
}

# Outputs print useful values after apply. These let you find what was created.
output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

# The blob endpoint URL, handy to paste into a browser or a later lab.
output "primary_blob_endpoint" {
  value = azurerm_storage_account.this.primary_blob_endpoint
}
