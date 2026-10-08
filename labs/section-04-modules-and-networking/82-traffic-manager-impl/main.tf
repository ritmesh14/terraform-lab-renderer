# Lab 82 — Traffic Manager with PRIORITY routing (active/passive failover).
# Same shape as lab 81 but traffic_routing_method = "Priority".
#  - Two web apps in different regions.
#  - One endpoint each, with priority 1 and 2. ALL traffic goes to priority 1;
#    if it's unhealthy, TM fails over to priority 2 automatically.
# Locals: named expressions computed once per run (not stored in state).
locals {
  regions = ["eastus", "westus2"]
}

# A stateful random string. Unlike md5(timestamp()) this value is SAVED in
# Terraform state, so it only changes when the resource is destroyed —
# every plan/apply is stable and nothing gets unexpectedly replaced.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# One resource group (in the primary region) holding both web apps.
resource "azurerm_resource_group" "this" {
  name     = "rg-tm-impl"
  location = local.regions[0]
}

# Two App Service plans — one per region (count = 2 mirrors the locals list).
resource "azurerm_service_plan" "this" {
  count               = 2
  name                = "asp-tmimpl-${count.index}"
  location            = local.regions[count.index]
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Linux"
  sku_name            = "B1"
}

# Two web apps, one per plan/region. count.index picks the matching plan.
resource "azurerm_linux_web_app" "this" {
  count               = 2
  name                = "app-tmimpl-${count.index}-${random_string.suffix.result}"
  location            = local.regions[count.index]
  resource_group_name = azurerm_resource_group.this.name
  service_plan_id     = azurerm_service_plan.this[count.index].id
  site_config {
    application_stack { node_version = "18-lts" }
  }
}

# The Traffic Manager profile: Priority routing + DNS name + health monitor.
resource "azurerm_traffic_manager_profile" "this" {
  name                   = "tmimpl-${random_string.suffix.result}"
  resource_group_name    = azurerm_resource_group.this.name
  traffic_routing_method = "Priority"

  dns_config {
    relative_name = "tmimpl-${random_string.suffix.result}"
    ttl           = 30
  }
  monitor_config {
    protocol = "HTTP"
    port     = 80
    path     = "/"
  }

}

# In azurerm 3.x endpoints are typed resources pointing at the profile.
# Priority 1 takes all traffic; priority 2 is the failover target.
resource "azurerm_traffic_manager_azure_endpoint" "eastus" {
  name               = "ep-eastus"
  profile_id         = azurerm_traffic_manager_profile.this.id
  target_resource_id = azurerm_linux_web_app.this[0].id
  priority           = 1
}

resource "azurerm_traffic_manager_azure_endpoint" "westus2" {
  name               = "ep-westus2"
  profile_id         = azurerm_traffic_manager_profile.this.id
  target_resource_id = azurerm_linux_web_app.this[1].id
  priority           = 2
}

# This DNS name always resolves to the priority-1 app while it is healthy.
output "tm_dns" { value = azurerm_traffic_manager_profile.this.fqdn }
