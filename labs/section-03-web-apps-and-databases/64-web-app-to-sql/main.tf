# Lab 64 — connect a web app to a SQL database.
# We inject the SQL connection string into the app's app_settings. Marking it
# sensitive in the setting keeps it out of plain logs. The SQL firewall rule
# 0.0.0.0 lets the Azure-hosted app reach the SQL server.

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
  name     = "rg-webapp-sql"
  location = "eastus"
}

# The logical SQL server the web app will talk to. Server names are globally
# unique (DNS), hence the random suffix.
resource "azurerm_mssql_server" "this" {
  name                         = "sqlserver-webapp-${random_string.suffix.result}"
  resource_group_name          = azurerm_resource_group.this.name
  location                     = azurerm_resource_group.this.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = var.sql_admin_password
}

# Allow Azure-internal services (like our App Service) to reach the SQL server.
resource "azurerm_mssql_firewall_rule" "azure" {
  name             = "AllowAzure"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# The database the app connects to. Its name is interpolated into the
# connection string below.
resource "azurerm_mssql_database" "this" {
  name      = "sqldb-webapp"
  server_id = azurerm_mssql_server.this.id
  sku_name  = "Basic"
}

# The Service Plan = the compute tier the web app runs on (B1 Basic, Linux).
resource "azurerm_service_plan" "this" {
  name                = "asp-webapp-sql"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Linux"
  sku_name            = "B1"
}

# The Linux Web App that will read the SQL connection string at runtime.
resource "azurerm_linux_web_app" "this" {
  name                = "app-webapp-sql-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  service_plan_id     = azurerm_service_plan.this.id
  site_config {
    application_stack { node_version = "18-lts" }
  }

  # app_settings are environment variables for the app. The connection string is
  # built from the server/database + the sensitive password.
  app_settings = {
    "DATABASE_URL" = "Server=tcp:${azurerm_mssql_server.this.fully_qualified_domain_name},1433;Database=${azurerm_mssql_database.this.name};User Id=sqladmin;Password=${var.sql_admin_password};Encrypt=true;"
  }
}

# Outputs print values after apply — the app URL and the SQL server address.
output "webapp_hostname" { value = azurerm_linux_web_app.this.default_hostname }
output "sql_fqdn" { value = azurerm_mssql_server.this.fully_qualified_domain_name }
