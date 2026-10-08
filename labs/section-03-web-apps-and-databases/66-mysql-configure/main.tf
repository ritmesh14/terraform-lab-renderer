# Lab 66 — configure the MySQL server (create a database + client firewall rule).
# We look up the EXISTING server with a data block (created in lab 65), then add a
# database and a firewall rule for your client IP so you can connect from a GUI.

# No default + sensitive: Terraform won't plan until you pass the password,
# and it stays hidden in plan/apply output.
variable "mysql_admin_password" {
  type      = string
  sensitive = true
}
# Point these at the server created in lab 65 (name is on that resource, or in
# its state/outputs); client_ip is the public IP you connect from.
variable "existing_server_name" { type = string }
variable "existing_rg_name" { type = string }
variable "client_ip" { type = string }

# Read the existing server (we don't manage it here).
data "azurerm_mysql_flexible_server" "this" {
  name                = var.existing_server_name
  resource_group_name = var.existing_rg_name
}

# Create a database with a specific charset/collation (utf8mb4 supports emoji etc.).
resource "azurerm_mysql_flexible_database" "app" {
  name                = "dbapp"
  resource_group_name = var.existing_rg_name
  server_name         = data.azurerm_mysql_flexible_server.this.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

# Allow YOUR client IP so you can connect with the mysql CLI or Workbench.
resource "azurerm_mysql_flexible_server_firewall_rule" "client" {
  name                = "AllowClient"
  resource_group_name = var.existing_rg_name
  server_name         = data.azurerm_mysql_flexible_server.this.name
  start_ip_address    = var.client_ip
  end_ip_address      = var.client_ip
}

# Outputs print values after apply — use the FQDN + db name in your connection.
output "database_name" { value = azurerm_mysql_flexible_database.app.name }
output "mysql_fqdn" { value = data.azurerm_mysql_flexible_server.this.fqdn }
