# Lab 60 (assignment) — scale a SQL database by changing its SKU via a variable.
# Change tfvars from Basic → S0 → S1 and watch `terraform plan` show an in-place
# SKU update (no destroy/create).

# No default + sensitive: Terraform won't plan until you pass the password,
# and it stays hidden in plan/apply output.
variable "sql_admin_password" {
  type      = string
  sensitive = true
}
# The DB SKU to deploy: DTU tiers are Basic, S0, S1, ... P1, ...; vCore tiers
# look like "GP_Gen5_2". Change this in tfvars to scale up or down.
variable "sku_name" {
  type    = string
  default = "Basic"
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
  name     = "rg-sql-dtu"
  location = "eastus"
}

# Same logical server pattern as lab 58 (fresh copy so this lab is self-contained).
resource "azurerm_mssql_server" "this" {
  name                         = "sqlserver-dtu-${random_string.suffix.result}"
  resource_group_name          = azurerm_resource_group.this.name
  location                     = azurerm_resource_group.this.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = var.sql_admin_password
}

resource "azurerm_mssql_database" "this" {
  name      = "sqldb-dtu"
  server_id = azurerm_mssql_server.this.id
  sku_name  = var.sku_name # scaling is just changing this value
}

# Outputs print values after apply — confirms which SKU is live.
output "sku" { value = azurerm_mssql_database.this.sku_name }
