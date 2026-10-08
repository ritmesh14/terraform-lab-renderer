# Lab 72 — MySQL Flexible Server: configuration + zone-redundant HA.
# Beyond basics: set high_availability = ZoneRedundant (2 instances across zones),
# tune a server parameter (max_connections), and set a maintenance window.
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

# No default + sensitive: Terraform won't plan until you pass the password,
# and it stays hidden in plan/apply output.
variable "mysql_admin_password" {
  type      = string
  sensitive = true
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
  name     = "rg-mysql-adv"
  location = "eastus"
}

# The managed MySQL server, this time with availability features configured
# inline: HA mode, maintenance window and an availability zone.
resource "azurerm_mysql_flexible_server" "this" {
  name                   = "mysql-adv-${random_string.suffix.result}"
  resource_group_name    = azurerm_resource_group.this.name
  location               = azurerm_resource_group.this.location
  administrator_login    = "mysqladmin"
  administrator_password = var.mysql_admin_password
  sku_name               = "B_Standard_B1ms"
  version                = "8.0.21"
  storage {
    size_gb = 20
  }
  zone = "1" # primary instance pinned to zone 1

  # Zone-redundant HA: a standby replica in another zone → automatic failover.
  high_availability {
    mode = "ZoneRedundant"
  }

  # Patching only during this weekly window (Sunday 02:00).
  maintenance_window {
    day_of_week  = 0
    start_hour   = 2
    start_minute = 0
  }
}

# Tune a single server parameter (max_connections).
resource "azurerm_mysql_flexible_server_configuration" "max_conn" {
  name                = "max_connections"
  resource_group_name = azurerm_resource_group.this.name
  server_name         = azurerm_mysql_flexible_server.this.name
  value               = "200"
}

# Outputs print values after apply — the address to connect to.
output "mysql_fqdn" { value = azurerm_mysql_flexible_server.this.fqdn }
