# Lab 59 — SQL firewall rules.
# By default NOTHING can reach a SQL logical server. We add two rules:
#   - one for your client IP (so you can connect from your machine)
#   - one for "0.0.0.0" (the special range meaning "other Azure services")

# No default + sensitive: Terraform won't plan until you pass the password,
# and it stays hidden in plan/apply output.
variable "sql_admin_password" {
  type      = string
  sensitive = true
}
# The public IP of the machine you'll connect from (find it: whatismyip).
variable "client_ip" { type = string }

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
  name     = "rg-sql-fw"
  location = "eastus"
}

# Same logical server as lab 58 (fresh copy here so this lab is self-contained).
resource "azurerm_mssql_server" "this" {
  name                         = "sqlserver-fw-${random_string.suffix.result}"
  resource_group_name          = azurerm_resource_group.this.name
  location                     = azurerm_resource_group.this.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.2"
}

# Allow YOUR client IP to connect (e.g. from SSMS / Azure Data Studio).
resource "azurerm_mssql_firewall_rule" "client" {
  name             = "AllowClient"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = var.client_ip
  end_ip_address   = var.client_ip
}

# 0.0.0.0-0.0.0.0 is the special "allow Azure-internal services" rule. It lets an
# App Service (or other Azure resource) reach the SQL server using its identity.
resource "azurerm_mssql_firewall_rule" "azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Outputs print values after apply — use this FQDN when connecting from SSMS.
output "server_fqdn" { value = azurerm_mssql_server.this.fully_qualified_domain_name }
