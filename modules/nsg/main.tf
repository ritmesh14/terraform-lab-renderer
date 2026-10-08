# Module: an NSG with one Allow rule per port in allowed_ports (dynamic block),
# associated with the given subnet.
# CONTRACT: inputs name, location, resource_group_name, allowed_ports, subnet_id
# → output nsg_id. The caller never writes a security_rule block itself.

# Terraform block: the module's own provider/version requirements.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }
  }
}

# --- INPUTS (what callers must pass in) ---

variable "name" {
  description = "NSG name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Existing resource group to deploy into."
  type        = string
}

variable "allowed_ports" {
  description = "Ports to allow inbound; one rule is created per port."
  type        = list(number)
}

variable "subnet_id" {
  description = "Subnet to associate the NSG with."
  type        = string
}

# --- RESOURCES ---

resource "azurerm_network_security_group" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  # dynamic builds one security_rule block per element of allowed_ports.
  dynamic "security_rule" {
    for_each = { for idx, port in var.allowed_ports : tostring(port) => idx }

    content {
      name                       = "Allow-${security_rule.key}"
      priority                   = 100 + security_rule.value
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = security_rule.key
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
}

# Attaching at the subnet level protects every NIC in that subnet.
resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.this.id
}

# --- OUTPUTS (what callers get back as module.<alias>.<output>) ---

output "nsg_id" {
  value = azurerm_network_security_group.this.id
}