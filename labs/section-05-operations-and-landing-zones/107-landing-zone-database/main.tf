# Lab 107 — Landing Zone: database.
#  - A SQL logical server + database in the data RG.
#  - A firewall rule (0.0.0.0) so Azure-internal apps can connect.
#  - azurerm_monitor_diagnostic_setting streams SQL logs/metrics to the Log Analytics
#    workspace from lab 105 (pass its id via var.log_workspace_id).
# SQL admin password, supplied via terraform.tfvars / -var. `sensitive` keeps it out
# of plan/apply logs and `terraform output`.
variable "sql_admin_password" {
  type      = string
  sensitive = true
}
# Resource ID of the central Log Analytics workspace (output from lab 105).
variable "log_workspace_id" { type = string }

# A stateful random string. Unlike md5(timestamp()) this value is SAVED in
# Terraform state, so it only changes when the resource is destroyed —
# every plan/apply is stable and nothing gets unexpectedly replaced.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Data RG for this lab's SQL server.
resource "azurerm_resource_group" "data" {
  name     = "rg-lz-db"
  location = "eastus"
}

# SQL logical server: the management endpoint that hosts databases (not the DB itself).
# The password comes from the sensitive variable — it never appears in logs.
resource "azurerm_mssql_server" "this" {
  # Interpolation keeps the globally-unique server name collision-free.
  name                         = "sql-lz-${random_string.suffix.result}"
  resource_group_name          = azurerm_resource_group.data.name
  location                     = azurerm_resource_group.data.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.2"
}

# Firewall rule "AllowAzure": 0.0.0.0 is Azure's special marker meaning
# "connections from inside Azure" (e.g. your app server or Power BI), NOT the public internet.
resource "azurerm_mssql_firewall_rule" "azure" {
  name             = "AllowAzure"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# The actual database on the server, smallest paid SKU (S0) — enough for a demo.
resource "azurerm_mssql_database" "this" {
  name      = "sqldb-lz"
  server_id = azurerm_mssql_server.this.id
  sku_name  = "S0"
}

# Diagnostic setting: streams this database's logs + metrics into the central
# Log Analytics workspace (lab 105). Without it, the SQL telemetry goes nowhere.
resource "azurerm_monitor_diagnostic_setting" "sql" {
  name                       = "diag-sql"
  target_resource_id         = azurerm_mssql_database.this.id # the resource being watched
  log_analytics_workspace_id = var.log_workspace_id           # the destination

  # Which log categories to stream. SQLSecurityAuditEvents = the audit trail of
  # access and queries (fails/permissions etc.).
  enabled_log {
    category = "SQLSecurityAuditEvents"
  }

  # Send the database's platform metrics too.
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Output: server's public DNS name — what you connect to with SSMS/az sql.
output "server_fqdn" { value = azurerm_mssql_server.this.fully_qualified_domain_name }
