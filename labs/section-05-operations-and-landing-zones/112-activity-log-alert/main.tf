# Lab 112 — an ACTIVITY LOG alert + webhook action group.
# Unlike a METRIC alert (numbers over time), activity-log alerts fire on control-plane
# EVENTS. Here: when a resource group is deleted in the subscription. The action group
# has a webhook receiver (point var.webhook_url at Slack/Teams or a requestbin).
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }

  }
}
provider "azurerm" {
  features {}
}

# The webhook endpoint to POST the alert payload to. Marked sensitive so the URL
# (which typically contains a secret token) stays out of logs and outputs.
variable "webhook_url" {
  type      = string
  sensitive = true
}

# Data source: the subscription Terraform is signed into — needed because activity-log
# alerts are scoped at subscription level (that's where control-plane events live).
data "azurerm_subscription" "current" {}

# Resource group holding the action group + alert rule.
resource "azurerm_resource_group" "this" {
  name     = "rg-activity-alert"
  location = "eastus"
}

# Action group: the notification channel. Instead of lab 99's email, this one has a
# WEBHOOK receiver — when it fires, Azure POSTs a JSON alert payload to that URL.
resource "azurerm_monitor_action_group" "this" {
  name                = "ag-rg-delete"
  resource_group_name = azurerm_resource_group.this.name
  short_name          = "rgdel" # max 12 chars, shows up in SMS/push texts

  webhook_receiver {
    name        = "notify-webhook"
    service_uri = var.webhook_url
  }
}

# Activity-log alert: fires on control-plane EVENTS rather than metric values.
# This one watches the WHOLE subscription for resource-group deletions.
resource "azurerm_monitor_activity_log_alert" "rg_delete" {
  name                = "alert-rg-delete"
  resource_group_name = azurerm_resource_group.this.name
  location            = "global" # activity log is a global service, not regional
  scopes              = [data.azurerm_subscription.current.id]

  # The matching conditions on the activity log entry:
  #   category = Administrative (control-plane write/delete operations)
  #   operation_name = the exact ARM operation: "delete a resource group"
  #   level = only Critical-severity log entries (deletions are Critical)
  criteria {
    category       = "Administrative"
    operation_name = "Microsoft.Resources/subscriptions/resourceGroups/delete"
    level          = "Critical"
  }

  # On match, notify this action group (webhook → your endpoint).
  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }

  description = "Fires when a resource group is deleted in the subscription."
}

# Output: the action group ID, so other alerts can reuse the same webhook channel.
output "action_group_id" { value = azurerm_monitor_action_group.this.id }
