# Lab 67 — deploy a web app that points at a MySQL database.
# The MySQL connection string is built from the server (declared here) and stored
# in the web app's app_settings.

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
  name     = "rg-webapp-mysql"
  location = "eastus"
}

# The managed MySQL server (same pattern as lab 65). Server names are globally
# unique (DNS), hence the random suffix.
resource "azurerm_mysql_flexible_server" "this" {
  name                   = "mysql-web-${random_string.suffix.result}"
  resource_group_name    = azurerm_resource_group.this.name
  location               = azurerm_resource_group.this.location
  administrator_login    = "mysqladmin"
  administrator_password = var.mysql_admin_password
  sku_name               = "B_Standard_B1ms"
  version                = "8.0.21"
  storage {
    size_gb = 20
  }
}

# The database the app uses; its name is interpolated into DATABASE_URL below.
resource "azurerm_mysql_flexible_database" "app" {
  name                = "dbapp"
  resource_group_name = azurerm_resource_group.this.name
  server_name         = azurerm_mysql_flexible_server.this.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

# The Service Plan = the compute tier the web app runs on (B1 Basic, Linux).
resource "azurerm_service_plan" "this" {
  name                = "asp-webapp-mysql"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Linux"
  sku_name            = "B1"
}

# The Linux Web App that reads DATABASE_URL at runtime.
resource "azurerm_linux_web_app" "this" {
  name                = "app-mysql-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  service_plan_id     = azurerm_service_plan.this.id
  site_config {
    application_stack { node_version = "18-lts" }
  }

  # DATABASE_URL = mysql://user:pass@host:3306/dbname
  app_settings = {
    "DATABASE_URL" = "mysql://mysqladmin:${var.mysql_admin_password}@${azurerm_mysql_flexible_server.this.fqdn}:3306/${azurerm_mysql_flexible_database.app.name}"
  }
}

# Outputs print values after apply — the app URL and the MySQL server address.
output "webapp_hostname" { value = azurerm_linux_web_app.this.default_hostname }
output "mysql_fqdn" { value = azurerm_mysql_flexible_server.this.fqdn }
