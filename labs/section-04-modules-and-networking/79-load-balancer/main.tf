# Lab 79 — Azure public Standard Load Balancer.
# Pieces (all part of a load balancer):
#  - frontend IP: the public address clients hit (here a public IP).
#  - backend pool: the set of VM NICs that receive traffic.
#  - probe: a health check (HTTP GET /) — only healthy VMs get traffic.
#  - rule: maps frontend port → backend port, using the probe.
# Two backend VMs run nginx via cloud-init so the LB serves HTTP.

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
      - echo "<h1>backend $(hostname)</h1>" > /var/www/html/index.html
  EOT
}

# Resource group everything in this lab goes into.
resource "azurerm_resource_group" "this" {
  name     = "rg-lb"
  location = "eastus"
}

# The network the backends live in.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-lb"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.16.0.0/16"]
}

# One subnet holds both backend VMs (10.16.1.0/24).
resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.16.1.0/24"]
}

# NSG: allow HTTP (LB → VMs) and SSH (admin).
resource "azurerm_network_security_group" "web" {
  name                = "nsg-lb"
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
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 210
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Attach the NSG to the subnet (Azure applies NSGs at the subnet or NIC level).
resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

# 2 backend NICs (no public IPs — the LB owns the public IP).
resource "azurerm_network_interface" "web" {
  count               = 2
  name                = "nic-lb-${count.index}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }
}

# 2 backend VMs running nginx (cloud-init installs it at boot).
resource "azurerm_linux_virtual_machine" "web" {
  count                 = 2
  name                  = "vm-lb-${count.index}"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  size                  = "Standard_B1s"
  admin_username        = "azureadmin"
  network_interface_ids = [azurerm_network_interface.web[count.index].id]
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

# The public IP clients will hit.
resource "azurerm_public_ip" "lb" {
  name                = "pip-lb"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# The Load Balancer itself. frontend_ip_configuration uses the public IP.
resource "azurerm_lb" "this" {
  name                = "lb-web-public"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard" # Standard required for the public IP + zones

  frontend_ip_configuration {
    name                 = "fe" # this name is referenced by the rule
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

# The backend pool: which VMs receive traffic.
resource "azurerm_lb_backend_address_pool" "web" {
  name            = "be-pool"
  loadbalancer_id = azurerm_lb.this.id
}

# Put each backend NIC into the backend pool.
resource "azurerm_network_interface_backend_address_pool_association" "web" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.web[count.index].id
  ip_configuration_name   = "ipconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web.id
}

# Health probe: HTTP GET / every 5s; 2 consecutive successes = healthy.
resource "azurerm_lb_probe" "http" {
  name                = "http-probe"
  loadbalancer_id     = azurerm_lb.this.id
  protocol            = "Http"
  port                = 80
  request_path        = "/"
  interval_in_seconds = 5
  number_of_probes    = 2
}

# The rule: frontend:80 → backend:80 using the probe. Only healthy VMs get traffic.
resource "azurerm_lb_rule" "http" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.this.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "fe" # ties to the frontend above
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web.id]
  probe_id                       = azurerm_lb_probe.http.id
}

# The address to browse to — round-robins between the two nginx backends.
output "lb_public_ip" { value = azurerm_public_ip.lb.ip_address }
