# Lab 71 — SQL server with Microsoft Entra ID (Azure AD) admin.
# Entra ID admin lets you sign in with an identity (no shared password). We also
# enable a SystemAssigned managed identity so the server can later authenticate
# to other Azure resources without secrets.
# This pins the tooling: Terraform CLI version + the provider that talks to Azure.
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

# The azurerm provider is the "driver" Terraform uses to talk to Microsoft
# Azure. `features {}` is required (an empty block is fine) and turns on
# default behaviour.
provider "azurerm" {
  features {}
}

# A data source reads existing info. This one returns details about the identity
# running Terraform (you, after az login) — its object_id/tenant_id are used below.
data "azurerm_client_config" "current" {}

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
  name     = "rg-sql-entra"
  location = "eastus"
}

# The logical SQL server. A hard-coded password is used just to satisfy the
# required field; the real sign-in path here is the Entra admin below.
resource "azurerm_mssql_server" "this" {
  name                = "sql-entra-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  version             = "12.0"

  # A SQL login for bootstrapping; Entra admin is the primary auth path.
  administrator_login          = "sqladmin"
  administrator_login_password = "ChangeMe12345!"
  minimum_tls_version          = "1.2"

  # Set the Entra admin to the current signed-in principal.
  azuread_administrator {
    login_username = "EntraAdmin"
    object_id      = data.azurerm_client_config.current.object_id
    tenant_id      = data.azurerm_client_config.current.tenant_id
  }

  identity { type = "SystemAssigned" } # server gets a managed identity
}

# The database lives on the server. sku_name "Basic" = 5 DTU (cheapest tier).
resource "azurerm_mssql_database" "this" {
  name      = "sqldb-entra"
  server_id = azurerm_mssql_server.this.id
  sku_name  = "Basic"
}

# Outputs print values after apply — the address to connect to with Entra auth.
output "server_fqdn" { value = azurerm_mssql_server.this.fully_qualified_domain_name }
