# Lab 69 — App Service auto-scale.
# A B1 plan is fixed. We use a Premium V3 plan (P1v3) which supports autoscale, with
# rules: scale out > 70% CPU, scale in < 30%, between 1 and 3 instances. The same
# azurerm_monitor_autoscale_setting resource works on VMSS too.
# This pins the tooling: Terraform CLI version + the provider that talks to Azure.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# The azurerm provider is the "driver" Terraform uses to talk to Microsoft
# Azure. `features {}` is required (an empty block is fine) and turns on
# default behaviour.
provider "azurerm" {
  features {}
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
  name     = "rg-appscale"
  location = "eastus"
}

# The Service Plan = the compute tier AND the thing that gets scaled. Autoscale
# changes the plan's instance count; every app on the plan scales with it.
resource "azurerm_service_plan" "this" {
  name                = "asp-appscale"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Linux"
  sku_name            = "P1v3" # Premium V3 enables autoscale
}

# The Linux Web App riding on the autoscaling plan above.
resource "azurerm_linux_web_app" "this" {
  name                = "app-appscale-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  service_plan_id     = azurerm_service_plan.this.id
  site_config {
    application_stack { node_version = "18-lts" }
  }
}

# Autoscale rules live in one monitor setting that points at the plan. A
# profile is a policy set; "default" applies at all times (no recurrence set).
resource "azurerm_monitor_autoscale_setting" "plan" {
  name                = "autoscale-asp"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  target_resource_id  = azurerm_service_plan.this.id # what we scale

  profile {
    name = "default"
    capacity {
      default = 1 # starting instance count
      minimum = 1
      maximum = 3
    }
    # Scale OUT: average CPU > 70% → add 1 instance.
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.this.id
        time_grain         = "PT1M" # ISO 8601: 1 minute
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT1M"
      }
    }
    # Scale IN: average CPU < 30% → remove 1 instance.
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.this.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT1M"
      }
    }
  }
}

# Outputs print values after apply — the app's live URL.
output "hostname" { value = azurerm_linux_web_app.this.default_hostname }
