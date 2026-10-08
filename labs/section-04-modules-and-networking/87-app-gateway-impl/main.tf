# Lab 87 — Application Gateway v2 (Layer 7) self-contained.
# App Gateway is an L7 load balancer (path/cookie/WAF). Pieces:
#  - VNet + appgw subnet (App Gateway lives in its own subnet).
#  - public IP for the frontend.
#  - sku Standard_v2 (the v2 line).
#  - frontend_port (80), frontend_ip_configuration (uses the public IP).
#  - backend_address_pool (IPs of the backend VMs, passed via var).
#  - backend_http_settings (port 80, http).
#  - http_listener (port 80) + request_routing_rule (listener → pool).
# Input for the module-style contract: lab 86's backend_ips output goes here.
variable "backend_ips" {
  type        = list(string)
  description = "Private IPs of the backend VMs from lab 97."
}

# Resource group everything in this lab goes into.
resource "azurerm_resource_group" "this" {
  name     = "rg-appgw-impl"
  location = "eastus"
}

# The VNet with the dedicated appgw subnet the gateway deploys into.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-appgw-impl"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.27.0.0/16"]
}

# App Gateway needs a dedicated, empty subnet (v2 also wants /26 or larger).
resource "azurerm_subnet" "appgw" {
  name                 = "snet-appgw"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.27.1.0/24"]
}

# The public IP clients browse to (Standard SKU, required by App Gateway v2).
resource "azurerm_public_ip" "appgw" {
  name                = "pip-appgw"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# The Application Gateway — an L7 (HTTP) load balancer. Its config is a chain:
# listener → (routing rule / path map) → backend pool + http settings.
resource "azurerm_application_gateway" "this" {
  name                = "appgw"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  # sku: Standard_v2 (v1 is legacy). capacity = min instance count of the gateway.
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  # The gateway's own network interface — lives in the dedicated appgw subnet.
  gateway_ip_configuration {
    name      = "ipconfig"
    subnet_id = azurerm_subnet.appgw.id
  }

  # Port the gateway listens on (referenced by name from the listener).
  frontend_port {
    name = "http"
    port = 80
  }

  # Frontend = the public IP (an internal frontend would use subnet_id instead).
  frontend_ip_configuration {
    name                 = "fe"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  # Backend pool = the VMs' private IPs (passed in from lab 86 via var).
  backend_address_pool {
    name         = "be-pool"
    ip_addresses = var.backend_ips
  }

  # How the gateway talks to the backends: plain HTTP on port 80.
  backend_http_settings {
    name                  = "http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  # Listener: waits for HTTP on the frontend IP + port.
  http_listener {
    name                           = "listener"
    frontend_ip_configuration_name = "fe"
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  # Routing rule ties the chain together: this listener → this pool + settings.
  # priority is required for v2 (order of rule evaluation, 1 = highest).
  request_routing_rule {
    name                       = "rule"
    rule_type                  = "Basic"
    http_listener_name         = "listener"
    backend_address_pool_name  = "be-pool"
    backend_http_settings_name = "http-settings"
    priority                   = 1
  }
}

# Browse this — requests are proxied to the nginx backends from lab 86.
output "appgw_public_ip" { value = azurerm_public_ip.appgw.ip_address }
