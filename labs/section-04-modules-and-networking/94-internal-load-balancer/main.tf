# Lab 94 — an INTERNAL Load Balancer (private frontend IP).
# Same shape as lab 79, but the LB frontend is a PRIVATE IP in a subnet, so the
# load-balanced service is only reachable from inside the VNet (classic internal-API
# pattern behind a public gateway/firewall).
#  - VNet 172.23.0.0/20 with a backend subnet (172.23.0.0/26) and a frontend subnet
#    (172.23.0.64/26) where the LB's private frontend IP (172.23.0.68) lives.
#  - 2 backend VMs run nginx; the LB rule maps 80→80 with an HTTP probe.

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
    runcmd:
      - systemctl enable --now nginx
      - echo "<h1>internal backend $(hostname)</h1>" > /var/www/html/index.html
  EOT
}

# Resource group everything in this lab goes into.
resource "azurerm_resource_group" "this" {
  name     = "rg-internal-lb"
  location = "eastus"
}

# The VNet (a /20 is plenty) holding both the LB frontend and the backends.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-internal-lb"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["172.23.0.0/20"]
}

# Backend subnet: where the two nginx VMs live.
resource "azurerm_subnet" "backend" {
  name                 = "snet-backend"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["172.23.0.0/26"]
}

# Frontend subnet: the internal LB gets its private IP from here. Azure
# recommends keeping the LB frontend in its own subnet (not with the backends).
resource "azurerm_subnet" "frontend" {
  name                 = "snet-frontend"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["172.23.0.64/26"]
}

# NSG: allow HTTP from within the VNet (this service has no public front door).
resource "azurerm_network_security_group" "web" {
  name                = "nsg-internal-lb"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# 2 backend NICs — private IPs only; nothing here is internet-reachable.
resource "azurerm_network_interface" "backend" {
  count               = 2
  name                = "nic-internal-be-${count.index}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }
}

# 2 nginx VMs serving a hostname-stamped page so you can see which backend answered.
resource "azurerm_linux_virtual_machine" "backend" {
  count                 = 2
  name                  = "vm-internal-be-${count.index}"
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

# The LB frontend is a PRIVATE IP in the frontend subnet.
resource "azurerm_lb" "this" {
  name                = "lb-internal"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "fe-internal"
    subnet_id                     = azurerm_subnet.frontend.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "172.23.0.68"
  }
}

# The backend pool: which VMs receive traffic.
resource "azurerm_lb_backend_address_pool" "web" {
  name            = "be-internal"
  loadbalancer_id = azurerm_lb.this.id
}

# Put each backend NIC into the backend pool.
resource "azurerm_network_interface_backend_address_pool_association" "web" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.backend[count.index].id
  ip_configuration_name   = "ipconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web.id
}

# Health probe: HTTP GET / (default 15s interval); only healthy VMs get traffic.
resource "azurerm_lb_probe" "http" {
  name            = "http"
  loadbalancer_id = azurerm_lb.this.id
  protocol        = "Http"
  port            = 80
  request_path    = "/"
}

# The rule: frontend:80 → backend:80 using the probe.
resource "azurerm_lb_rule" "http" {
  name                           = "http"
  loadbalancer_id                = azurerm_lb.this.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "fe-internal"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web.id]
  probe_id                       = azurerm_lb_probe.http.id
}

# Test from INSIDE the VNet only (e.g. SSH to a VM and curl this address).
output "lb_private_ip" { value = "172.23.0.68" }
