# Lab 62 — two databases on one logical server, with a connection-string output.
# Teaches: one server can host many databases, and you can build a full ADO
# connection string with string interpolation (${...}) and mark it sensitive.

# No default + sensitive: Terraform won't plan until you pass the password,
# and it stays hidden in plan/apply output.
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
  name     = "rg-sql-two"
  location = "eastus"
}

# The logical SQL server — like the "instance" that hosts the databases below.
# Server names are globally unique (DNS), hence the random suffix.
resource "azurerm_mssql_server" "this" {
  name                         = "sqlserver-two-${random_string.suffix.result}"
  resource_group_name          = azurerm_resource_group.this.name
  location                     = azurerm_resource_group.this.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = var.sql_admin_password
}

# Two databases SHARING the same server (and admin).
resource "azurerm_mssql_database" "app" {
  name      = "sqldb-app"
  server_id = azurerm_mssql_server.this.id
  sku_name  = "Basic"
}

# Same server, different database — billing/SKU is per database.
resource "azurerm_mssql_database" "reports" {
  name      = "sqldb-reports"
  server_id = azurerm_mssql_server.this.id
  sku_name  = "Basic"
}

# Outputs print values after apply. This one is the server address apps connect to.
output "server_fqdn" { value = azurerm_mssql_server.this.fully_qualified_domain_name }
# A full ADO connection string you'd hand to an app. Sensitive so it's masked.
output "app_conn_string" {
  value     = "Server=tcp:${azurerm_mssql_server.this.fully_qualified_domain_name},1433;Database=sqldb-app;User Id=sqladmin;Password=${var.sql_admin_password};"
  sensitive = true
}
