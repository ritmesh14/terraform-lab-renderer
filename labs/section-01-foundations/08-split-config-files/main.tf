# ---------------------------------------------------------------------------
# Lab 08 — Split configuration files
# Same VNet as lab 07, but split across terraform.tf / locals.tf / main.tf /
# outputs.tf. Teaches that Terraform merges every *.tf in the folder into one
# config, so you can organize by concern.
# ---------------------------------------------------------------------------

# main.tf — the actual resources (references locals from locals.tf).

# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = local.rg_name
  location = local.region
  tags     = local.common_tags
}

# Virtual network, referencing locals defined in locals.tf — proof that a
# resource in one file can use values from another.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-${local.project}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.40.0.0/16"]
  tags                = local.common_tags
}
