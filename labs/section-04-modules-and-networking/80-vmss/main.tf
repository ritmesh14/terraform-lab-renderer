# Lab 80 — Virtual Machine Scale Set (VMSS) behind a public Load Balancer, with autoscale.
# A VMSS deploys IDENTICAL VMs that scale automatically. Pieces here:
#  - VNet + subnet for the VMSS.
#  - public Standard LB (frontend IP, backend pool, probe, rule) — same as lab 79.
#  - azurerm_linux_virtual_machine_scale_set: instances run nginx via cloud-init.
#  - azurerm_monitor_autoscale_setting: scale OUT > 75% CPU, scale IN < 25%, 1→5 instances.
# The scale set's NIC joins the LB backend pool via load_balancer_backend_address_pool_ids.

# Root variable for the scale set VMs' admin SSH key (kept out of CLI output).
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
  name     = "rg-vmss"
  location = "eastus"
}

# The network the scale set lives in.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-vmss"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.17.0.0/16"]
}

# One subnet holds every scale-set instance (10.17.1.0/24).
resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.17.1.0/24"]
}

# NSG: allow HTTP (LB → instances).
resource "azurerm_network_security_group" "web" {
  name                = "nsg-vmss"
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

# Attach the NSG to the subnet (Azure applies NSGs at the subnet or NIC level).
resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

# The public IP clients will hit (owned by the LB, not the instances).
resource "azurerm_public_ip" "lb" {
  name                = "pip-vmss"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# The Load Balancer in front of the scale set: frontend IP = the public IP.
resource "azurerm_lb" "this" {
  name                = "lb-vmss"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "fe"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

# The backend pool: which instances receive traffic (joined via the NIC block below).
resource "azurerm_lb_backend_address_pool" "web" {
  name            = "be-vmss"
  loadbalancer_id = azurerm_lb.this.id
}

# Health probe: HTTP GET / (default 15s interval); only healthy instances get traffic.
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
  frontend_ip_configuration_name = "fe"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web.id]
  probe_id                       = azurerm_lb_probe.http.id
}

# The scale set itself: identical instances created/destroyed automatically.
resource "azurerm_linux_virtual_machine_scale_set" "web" {
  name                = "vmss-web"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  # The scale set's VM size is the plain `sku` attribute in this provider version.
  sku            = "Standard_B1s"
  admin_username = "azureadmin"
  instances      = 2
  custom_data    = base64encode(local.cloud_init)

  admin_ssh_key {
    username   = "azureadmin"
    public_key = var.admin_ssh_key
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  network_interface {
    name    = "nic-vmss"
    primary = true
    # Every instance's NIC joins the LB backend pool here — that is how the
    # scale set (not individual NICs) is wired to the load balancer.
    ip_configuration {
      name                                   = "ipconfig"
      primary                                = true
      subnet_id                              = azurerm_subnet.web.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.web.id]
    }
  }
}

# Autoscale: watch CPU on the scale set and add/remove instances. ISO-8601
# durations: PT1M = 1 minute, PT5M = 5 minutes.
resource "azurerm_monitor_autoscale_setting" "web" {
  name                = "autoscale-vmss"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.web.id

  # One profile = one scaling policy: instance count bounds + the rules below.
  profile {
    name = "default"
    capacity {
      default = 2
      minimum = 2
      maximum = 5
    }
    # Scale OUT when the average CPU over 5 minutes exceeds 75% (+1 instance).
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.web.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT1M"
      }
    }
    # Scale IN when the average CPU over 5 minutes drops below 25% (−1 instance).
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.web.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
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

# The address to load-test (e.g. with `ab` or a browser refresh loop) to trigger scaling.
output "lb_public_ip" { value = azurerm_public_ip.lb.ip_address }
