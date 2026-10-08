# Lab 93 — consume a module from the public Terraform Registry.
#  - source = "Azure/network/azurerm" (namespace/name/provider) with a pinned version.
#  - `terraform init` downloads it; the .terraform.lock.hcl pins it.
# This is how you reuse community-maintained modules instead of writing everything.
# Outputs (vnet_id, subnet_ids) come from the registry module's declared outputs.

# Registry module: source = <namespace>/<name>/<provider> — NO path, NO https URL;
# `terraform init` downloads it from registry.terraform.io. Pinning `version`
# keeps your builds reproducible (no surprise major-version upgrades). The
# .terraform.lock.hcl that init creates records the exact chosen version.
# Inputs here: use_for_each, resource_group_name, address_space, subnet lists, tags.
# Outputs read below: vnet_id, vnet_subnets.
module "network" {
  source  = "Azure/network/azurerm"
  version = "5.2.0"

  use_for_each            = true
  resource_group_name     = "rg-registry-module"
  resource_group_location = "eastus"
  address_space           = "10.33.0.0/16"
  subnet_prefixes         = ["10.33.1.0/24", "10.33.2.0/24"]
  subnet_names            = ["web", "app"]
  tags = {
    managedby = "terraform"
    section   = "04-registry-module"
  }
}

# Outputs from the registry module. Note the subnet output is named
# vnet_subnets in this module (its own naming — read the module's docs).
output "vnet_id" { value = module.network.vnet_id }
output "subnet_ids" { value = module.network.vnet_subnets }
