# ---------------------------------------------------------------------------
# Lab 03 — Upload a Blob
# Builds: resource group "rg-blob-foundation", storage account "stblobfound<suffix>",
# container "uploads", block blob "hello.txt".
# Teaches: azurerm_storage_container + azurerm_storage_blob, and the difference
# between uploading inline content (source_content) and a local file (source).
# ---------------------------------------------------------------------------

# `locals {}` holds DERIVED values — names we compute once and reuse.
locals {
  region  = "eastus"
  rg_name = "rg-blob-foundation"
  # lower() forces the name to lowercase (Azure storage accounts require it);
  # the suffix from the random_string below keeps the name globally unique.
  st_name = lower("stblobfound${random_string.suffix.result}") # globally-unique name
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
  name     = local.rg_name
  location = local.region
}

# Storage account. Referencing the resource group's name/location here tells
# Terraform to create the RG first (implicit dependency).
resource "azurerm_storage_account" "this" {
  name                     = local.st_name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

# A container groups blobs. `container_access_type = "private"` means only
# authorized requests can read its blobs (good default for real data).
resource "azurerm_storage_container" "uploads" {
  name                  = "uploads"
  storage_account_name  = azurerm_storage_account.this.name # just the name string
  container_access_type = "private"
}

# A Block blob for small text/file uploads. `source_content` uploads inline text
# (use `source = "./file.png"` to upload a local file instead).
#
# GOTCHA — the timestamp() below: because it's inside source_content, its value
# is captured into Terraform STATE at apply time. On the NEXT plan, timestamp()
# has moved on, so the content no longer matches state and Terraform shows the
# blob wanting to UPDATE (in-place) on every run. This is the same reason we
# avoided md5(timestamp()) for the NAME in lab 02 — but here it only churns the
# blob's content, not the name, so nothing gets REPLACED. It's harmless in a
# lab, and it's a useful demo of the rule: keep volatile functions like
# timestamp() OUT of attributes that are diffed against state unless you want
# a drift every run.
resource "azurerm_storage_blob" "hello" {
  name                   = "hello.txt"
  storage_account_name   = azurerm_storage_account.this.name
  storage_container_name = azurerm_storage_container.uploads.name
  type                   = "Block" # Block = small files; Append/Page are other types
  source_content         = "Hello from Terraform!\nUploaded: ${timestamp()}"
  content_type           = "text/plain"
}

# Prints the blob's URL after apply — open it to confirm the upload worked
# (it will 404 on a private container without a SAS token; that is expected).
output "blob_url" { value = azurerm_storage_blob.hello.url }
