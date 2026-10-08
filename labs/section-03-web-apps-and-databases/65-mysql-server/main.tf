# Lab 65 — Azure Database for MySQL (Flexible Server).
# A managed MySQL 8 instance. Burstable B1ms is the smallest. Public access + a
# firewall rule for Azure services lets apps reach it.

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
  name     = "rg-mysql"
  location = "eastus"
}

# The managed MySQL server itself. Server names are globally unique (DNS),
# hence the random suffix. The nested storage {} block sets the data disk size.
resource "azurerm_mysql_flexible_server" "this" {
  name                   = "mysql-${random_string.suffix.result}"
  resource_group_name    = azurerm_resource_group.this.name
  location               = azurerm_resource_group.this.location
  administrator_login    = "mysqladmin"
  administrator_password = var.mysql_admin_password
  sku_name               = "B_Standard_B1ms" # burstable, 1 vCPU, 2GB
  version                = "8.0.21"
  storage {
    size_gb = 20
  }

}

# 0.0.0.0 = allow any Azure-internal IP to connect (so App Service can).
# In azurerm 3.x flexible firewall rules take resource_group_name + server_name
# (not a server_id).
resource "azurerm_mysql_flexible_server_firewall_rule" "azure" {
  name                = "AllowAzure"
  resource_group_name = azurerm_resource_group.this.name
  server_name         = azurerm_mysql_flexible_server.this.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# Outputs print values after apply — the address tools like MySQL Workbench
# connect to.
output "mysql_fqdn" { value = azurerm_mysql_flexible_server.this.fqdn }
