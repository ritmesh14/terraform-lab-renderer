# Lab 77 — the full vm-stack module: RG → VNet → subnet → NSG → public IP → NIC → VM.
# One `module` block stands up the whole stack.
# Builds: rg-modvm, vnet-modvm, subnet-modvm, nsg-modvm, pip-modvm, nic-modvm, vm-modvm.
# Concept: a big "stack" module — one input (SSH key) drives a whole environment.

# Terraform block: required CLI version + provider versions this config needs.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }

  }
}

# Provider block: configures azurerm. `features {}` is required (can stay empty).
provider "azurerm" {
  features {}
}

# Root variable for the module's admin_ssh_key input. `sensitive` keeps the key
# out of plan/apply CLI output (it is still stored in state in plain text).
variable "admin_ssh_key" {
  type      = string
  sensitive = true
}
module "stack" {
  source             = "../../modules/vm-stack"
  name_prefix        = "modvm" # drives all resource names
  location           = "eastus"
  admin_ssh_key      = var.admin_ssh_key
  vnet_address_space = ["10.14.0.0/16"]
  subnet_prefix      = "10.14.1.0/24"
  tags               = { project = "section-04", managedby = "terraform" }
}

# Outputs come from the module's declared outputs (public_ip, vm_name).
output "public_ip" { value = module.stack.public_ip }
output "vm_name" { value = module.stack.vm_name }
