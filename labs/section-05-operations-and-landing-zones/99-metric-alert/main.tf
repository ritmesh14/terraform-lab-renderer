# Lab 99 — a metric alert + action group.
#  - azurerm_monitor_action_group: WHO to notify (email receiver here).
#  - azurerm_monitor_metric_alert: a rule on a metric (VM Percentage CPU > 80% for 5m).
#    scopes = the VM resource id. When the rule fires, it triggers the action group.
# Point var.vm_resource_id at a VM (e.g. the one from lab 98).
variable "vm_resource_id" { type = string }
variable "admin_email" { type = string }

# Resource group for the monitoring pieces themselves (kept separate from the monitored VM).
resource "azurerm_resource_group" "this" {
  name     = "rg-alert"
  location = "eastus"
}

# Action group: WHO gets told when an alert fires. Here it's just one email receiver,
# but the same block also holds SMS, webhook, Logic App, ITSM receivers, etc.
resource "azurerm_monitor_action_group" "this" {
  name                = "ag-cpu-alert"
  resource_group_name = azurerm_resource_group.this.name
  short_name          = "cpualert"

  email_receiver {
    name          = "oncall"
    email_address = var.admin_email
  }
}

# Metric alert: WHEN to notify. This rule = "the VM's average CPU was over 80%
# during each 5-minute evaluation window". `scopes` is the resource (by ID) whose
# metric is watched — one alert can watch several resources.
resource "azurerm_monitor_metric_alert" "cpu" {
  name                = "alert-cpu-high"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [var.vm_resource_id]
  severity            = 2 # 0 (critical) … 4 (verbose); 2 = "warning"

  # The condition itself. Every field matters:
  #   metric_namespace = which Azure service emits the metric (Compute/VM here)
  #   metric_name      = the exact metric ("Percentage CPU", with spaces!)
  #   aggregation      = how points in the window are combined (Average)
  #   operator + threshold = the trigger line (Average CPU > 80)
  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  # window_size = the evaluation window (ISO-8601 duration): PT5M = 5 minutes.
  # Azure checks roughly every 1 minute, but the condition must hold over this window.
  window_size = "PT5M"

  # Wire the alert to the action group: when criteria fire, the notification goes out.
  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
}

# Output: the action group's ID, so other labs (or pipelines) can attach it to more alerts.
output "action_group_id" { value = azurerm_monitor_action_group.this.id }
