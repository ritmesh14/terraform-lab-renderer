# Lab 40 — a web server built via cloud-init (custom_data).
# Teaches: a heredoc (<<-EOT) holding cloud-init YAML, base64encode() for
# custom_data, a public IP attached to a NIC's ip_configuration, and an NSG rule
# opening HTTP.
# Instead of a provisioner, install nginx at first boot with cloud-init —
# idempotent and the Terraform-native way.

# Sensitive input: your SSH public key (no default → Terraform prompts, or pass
# with -var / tfvars). sensitive = true hides it in plan/apply output.
variable "admin_ssh_key" {
  type      = string
  sensitive = true
}
# locals: the cloud-init document (heredoc) fed to the VM's custom_data.
locals {
  # <<-EOT ... EOT is a heredoc. The indent is stripped. This is cloud-init YAML.
  cloud_init = <<-EOT
    #cloud-config
    package_update: true
    packages:
      - nginx
    runcmd:
      - systemctl enable --now nginx
      - echo "<h1>Hello from Terraform-built web server</h1>" > /var/www/html/index.html
  EOT
}

# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = "rg-webserver"
  location = "eastus"
}

# Virtual network + subnet: where the NIC (and its public IP) live.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-webserver"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.220.0.0/16"]
}

# Subnet: the /24 the NIC (and its public IP) attach to.
resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.220.1.0/24"]
}

# NSG allowing HTTP (80) so the site is reachable.
resource "azurerm_network_security_group" "web" {
  name                = "nsg-webserver"
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

# Public IP: allocated Static/Standard so the address survives VM restarts. It is
# attached to the NIC's ip_configuration below (not to the VM directly).
resource "azurerm_public_ip" "web" {
  name                = "pip-webserver"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# NIC: connects the VM to the subnet and (via ip_configuration) to the public IP.
resource "azurerm_network_interface" "web" {
  name                = "nic-webserver"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web.id
  }
}

# custom_data runs once at first boot. It MUST be base64-encoded.
resource "azurerm_linux_virtual_machine" "web" {
  name                  = "vm-webserver"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  size                  = "Standard_B1s"
  admin_username        = "azureadmin"
  network_interface_ids = [azurerm_network_interface.web.id]
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

# Output: the public IP Azure assigned (unknown until apply completes).
# Open http://<this IP> to see the nginx page cloud-init wrote.
output "public_ip" { value = azurerm_public_ip.web.ip_address }
