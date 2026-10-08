# Lab 105 — Landing Zone: central logging.
#  - A Log Analytics workspace (for querying) in the security RG.
#  - A storage account (for long-term log archive; diagnostic settings can target it).
# Resources send logs to both via diagnostic settings (lab 111 shows the wiring).
# A stateful random string. Unlike md5(timestamp()) this value is SAVED in
# Terraform state, so it only changes when the resource is destroyed —
# every plan/apply is stable and nothing gets unexpectedly replaced.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Security RG — the natural home for logging in a landing zone (see lab 103's layout).
resource "azurerm_resource_group" "sec" {
  name     = "rg-lz-sec"
  location = "eastus"
}

# Central Log Analytics workspace: the landing zone's "query everything here" store.
# Diagnostic settings in later labs send logs/metrics to it; KQL queries run here.
resource "azurerm_log_analytics_workspace" "this" {
  # Interpolation keeps the globally-unique workspace name collision-free.
  name                = "log-lz-${random_string.suffix.result}"
  location            = azurerm_resource_group.sec.location
  resource_group_name = azurerm_resource_group.sec.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Archive storage account: cheap long-term retention of logs that exceed the
# workspace's 30-day window (diagnostic settings can target a storage account).
resource "azurerm_storage_account" "logs" {
  # lower() + random suffix: storage names must be globally unique, lowercase, 3-24 chars.
  name                     = lower("stlzlogs${random_string.suffix.result}")
  resource_group_name      = azurerm_resource_group.sec.name
  location                 = azurerm_resource_group.sec.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

# Outputs for the next labs: workspace resource ID (diagnostic settings) and the
# storage account name (archive destination).
output "workspace_id" { value = azurerm_log_analytics_workspace.this.id }
output "logs_sa" { value = azurerm_storage_account.logs.name }
