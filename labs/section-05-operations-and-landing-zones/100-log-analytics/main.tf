# Lab 100 — a Log Analytics workspace.
# A workspace collects logs/metrics from resources. Other resources send data here
# via a diagnostic setting (see lab 111). sku PerGB2018 = pay per GB ingested.
# A stateful random string. Unlike md5(timestamp()) this value is SAVED in
# Terraform state, so it only changes when the resource is destroyed —
# every plan/apply is stable and nothing gets unexpectedly replaced.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Resource group holding the workspace.
resource "azurerm_resource_group" "this" {
  name     = "rg-loganalytics"
  location = "eastus"
}

# Log Analytics workspace: the central place where Azure collects logs and metrics.
# Diagnostic settings (lab 111) send resource logs here; KQL queries run against it.
# sku PerGB2018 = pay per GB ingested, retention_in_days = how long data is kept (30).
resource "azurerm_log_analytics_workspace" "this" {
  # Interpolation: the random suffix is baked into the name so the globally-unique
  # workspace name doesn't collide between runs/people.
  name                = "log-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Two DIFFERENT ids: `id` is the full Azure resource path (used by diagnostic settings,
# lab 111), `workspace_id` is the workspace's GUID (used by agents / the API).
output "workspace_id" { value = azurerm_log_analytics_workspace.this.id }
output "customer_id" { value = azurerm_log_analytics_workspace.this.workspace_id }
