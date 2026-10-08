# Lab 58 — Azure SQL Database.
# Create a logical SQL server + a single database. The admin password comes from
# a SENSITIVE variable. Storage is the cheapest DTU tier (Basic = 5 DTU, 2 GB).

# No default = Terraform refuses to plan until you supply it (-var, tfvars or
# env var). `sensitive = true` hides it in plan/apply output (state still
# stores it, so protect the state file too).
variable "sql_admin_password" {
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
  name     = "rg-sql"
  location = "eastus"
}

# A logical SQL server. Server names are globally unique (DNS).
resource "azurerm_mssql_server" "this" {
  name                         = "sqlserver-${random_string.suffix.result}"
  resource_group_name          = azurerm_resource_group.this.name
  location                     = azurerm_resource_group.this.location
  version                      = "12.0" # the SQL server version
  administrator_login          = "sqladmin"
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.2"
}

# The database lives on the server. sku_name "Basic" = 5 DTU.
resource "azurerm_mssql_database" "this" {
  name        = "sqldb-app"
  server_id   = azurerm_mssql_server.this.id
  sku_name    = "Basic"
  max_size_gb = 2
}

# The server's FQDN (e.g. sqlserver-ab12cd.database.windows.net) is what tools
# like SSMS/Azure Data Studio connect to.
output "server_fqdn" { value = azurerm_mssql_server.this.fully_qualified_domain_name }
output "database_name" { value = azurerm_mssql_database.this.name }
