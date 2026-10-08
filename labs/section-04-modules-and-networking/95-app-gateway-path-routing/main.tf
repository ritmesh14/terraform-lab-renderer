# Lab 95 — App Gateway path-based routing.
# One listener, three backend pools: /images/* → pool1, /video/* → pool2, default →
# pool3. The url_path_map + path_rule blocks implement the routing. This is the
# building block for hosting several services behind ONE domain/hostname.
# VNet 172.24.0.0/20; appgw subnet 172.24.0.0/26; backends subnet 172.24.0.64/26.

# Terraform block: which Terraform CLI and provider versions this lab requires.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }

  }
}

# Provider block: configures azurerm against the subscription from `az login`.
# `features {}` is an empty settings block the azurerm provider requires.
provider "azurerm" {
  features {}
}

# Root variable for the backend VMs' admin SSH key (kept out of CLI output).
variable "admin_ssh_key" {
  type      = string
  sensitive = true
}

# Locals: named expressions computed once per run (not stored in state).
locals {
  cloud_init = <<-EOT
    #cloud-config
    package_update: true
    packages: [nginx]
    runcmd: [ "systemctl enable --now nginx" ]
  EOT
}

# Resource group everything in this lab goes into.
resource "azurerm_resource_group" "this" {
  name     = "rg-appgw-path"
  location = "eastus"
}

# The VNet holding the gateway subnet and the backend subnet.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-appgw-path"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["172.24.0.0/20"]
}

# Dedicated, empty subnet for the gateway (App Gateway needs its own subnet).
resource "azurerm_subnet" "appgw" {
  name                 = "snet-appgw"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["172.24.0.0/26"]
}

# Subnet for the three backend VMs.
resource "azurerm_subnet" "backend" {
  name                 = "snet-backend"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["172.24.0.64/26"]
}

# 3 backend NICs — one VM per pool: [0]→images, [1]→video, [2]→default.
resource "azurerm_network_interface" "backend" {
  count               = 3
  name                = "nic-appgw-path-be-${count.index}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }
}

# 3 nginx VMs (all serve the same page — the gateway decides who gets which path).
resource "azurerm_linux_virtual_machine" "backend" {
  count                 = 3
  name                  = "vm-appgw-path-be-${count.index}"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  size                  = "Standard_B1s"
  admin_username        = "azureadmin"
  network_interface_ids = [azurerm_network_interface.backend[count.index].id]
  custom_data           = base64encode(local.cloud_init)
  admin_ssh_key {
    username   = "azureadmin"
    public_key = var.admin_ssh_key
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# The public IP clients browse to.
resource "azurerm_public_ip" "appgw" {
  name                = "pip-appgw-path"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# The Application Gateway with three pools and a url_path_map for path routing.
resource "azurerm_application_gateway" "this" {
  name                = "appgw-path"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "ipconfig"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_port {
    name = "http"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "fe"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  # One pool per path. Each pool gets exactly one VM (pulled by index), so a
  # request to /images/* always shows vm-...-0, /video/* → vm-...-1, else vm-...-2.
  backend_address_pool {
    name         = "be-images"
    ip_addresses = [azurerm_network_interface.backend[0].private_ip_address]
  }
  backend_address_pool {
    name         = "be-video"
    ip_addresses = [azurerm_network_interface.backend[1].private_ip_address]
  }
  backend_address_pool {
    name         = "be-default"
    ip_addresses = [azurerm_network_interface.backend[2].private_ip_address]
  }

  # How the gateway talks to the backends: plain HTTP on port 80 (shared by all pools).
  backend_http_settings {
    name                  = "http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  # Listener: waits for HTTP on the frontend IP + port (same as lab 87).
  http_listener {
    name                           = "listener"
    frontend_ip_configuration_name = "fe"
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  # Path-based rule: one listener, three paths.
  request_routing_rule {
    name               = "path-rule"
    rule_type          = "PathBasedRouting"
    http_listener_name = "listener"
    url_path_map_name  = "urlpaths" # must match the url_path_map name below
    priority           = 1
  }

  # The path map: which paths go to which pool, plus the default for anything else.
  url_path_map {
    name                               = "urlpaths"
    default_backend_address_pool_name  = "be-default"
    default_backend_http_settings_name = "http-settings"

    path_rule {
      name                       = "images"
      paths                      = ["/images/*"]
      backend_address_pool_name  = "be-images"
      backend_http_settings_name = "http-settings"
    }
    path_rule {
      name                       = "video"
      paths                      = ["/video/*"]
      backend_address_pool_name  = "be-video"
      backend_http_settings_name = "http-settings"
    }
  }
}

# Browse http://<ip>/images/, /video/, and anything else to see the routing.
output "appgw_public_ip" { value = azurerm_public_ip.appgw.ip_address }
