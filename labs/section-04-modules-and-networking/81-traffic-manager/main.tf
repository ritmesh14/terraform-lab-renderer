# Lab 81 — Traffic Manager (DNS-based global load balancer).
# Traffic Manager doesn't proxy traffic — it picks the best endpoint via DNS.
#  - Two web apps in DIFFERENT regions (eastus, westeurope) on Basic plans.
#  - A Traffic Manager profile with traffic_routing_method = "Performance"
#    (sends each user to the lowest-latency endpoint).
#  - One endpoint per web app (type = azureEndpoints, target_resource_id = the app).
# Users hit the TM DNS name; TM returns the nearest region's app hostname.
# Locals: named expressions computed once per run (not stored in state).
locals {
  regions = ["eastus", "westeurope"]
}

# A stateful random string. Unlike md5(timestamp()) this value is SAVED in
# Terraform state, so it only changes when the resource is destroyed —
# every plan/apply is stable and nothing gets unexpectedly replaced.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# One resource group (in the first region) holding both web apps.
resource "azurerm_resource_group" "this" {
  name     = "rg-tm"
  location = local.regions[0]
}

# Two App Service plans — one per region (count = 2 mirrors the locals list).
resource "azurerm_service_plan" "this" {
  count               = 2
  name                = "asp-tm-${count.index}"
  location            = local.regions[count.index]
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Linux"
  sku_name            = "B1"
}

# Two web apps, one per plan/region. count.index picks the matching plan.
resource "azurerm_linux_web_app" "this" {
  count               = 2
  name                = "app-tm-${count.index}-${random_string.suffix.result}"
  location            = local.regions[count.index]
  resource_group_name = azurerm_resource_group.this.name
  service_plan_id     = azurerm_service_plan.this[count.index].id
  site_config {
    application_stack { node_version = "18-lts" }
  }
  tags = { region = local.regions[count.index] }
}

# The Traffic Manager profile: routing method + DNS name + health monitor.
resource "azurerm_traffic_manager_profile" "this" {
  name                   = "tm-${random_string.suffix.result}"
  resource_group_name    = azurerm_resource_group.this.name
  traffic_routing_method = "Performance"

  dns_config {
    relative_name = "tm-${random_string.suffix.result}"
    ttl           = 30
  }

  monitor_config {
    protocol = "HTTP"
    port     = 80
    path     = "/"
  }

}

# In azurerm 3.x endpoints are typed resources pointing at the profile:
# azurerm_traffic_manager_azure_endpoint (for azureEndpoints).
resource "azurerm_traffic_manager_azure_endpoint" "eastus" {
  name               = "ep-eastus"
  profile_id         = azurerm_traffic_manager_profile.this.id
  target_resource_id = azurerm_linux_web_app.this[0].id
}

resource "azurerm_traffic_manager_azure_endpoint" "westeurope" {
  name               = "ep-westeurope"
  profile_id         = azurerm_traffic_manager_profile.this.id
  target_resource_id = azurerm_linux_web_app.this[1].id
}

# Browse this DNS name — it resolves to whichever app is closest to you.
output "tm_dns" { value = azurerm_traffic_manager_profile.this.fqdn }
