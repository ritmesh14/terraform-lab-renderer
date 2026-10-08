# Lab 110 — author a CUSTOM Azure Policy definition + assign it.
#  - azurerm_policy_definition: policyRule JSON — deny resource groups missing a
#    "costcenter" tag. Stored at the subscription scope.
#  - azurerm_resource_group_policy_assignment assigns the custom definition to an RG.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }

  }
}
# Provider block: connects Terraform to your Azure subscription via az cli credentials.
provider "azurerm" {
  features {}
}

# The RG we create must satisfy our own policy: the "costcenter" tag is present,
# so the deny effect never triggers for it.
resource "azurerm_resource_group" "this" {
  name     = "rg-custom-policy"
  location = "eastus"
  tags     = { costcenter = "cc-100" } # compliant with our own policy
}

# A custom policy definition (stored at the subscription scope).
# Unlike lab 109's built-in, here WE write the rule. Policy rules are JSON:
#   if  = when does this rule match? (here: a resource group missing tags.costcenter)
#   then = what happens? (deny = the creation/update is refused)
resource "azurerm_policy_definition" "require_costcenter" {
  name         = "require-costcenter-tag"
  policy_type  = "Custom" # "Custom" (ours) vs "BuiltIn" (Microsoft's)
  mode         = "All"    # evaluate all resource kinds, not just ARM-indexed ones
  display_name = "Require a costcenter tag on resource groups"

  # jsonencode turns this HCL map into the JSON string Azure expects.
  # allOf = both conditions must hold: the type is a resource group AND
  # `tags.costcenter` does not exist. field names come from Azure's ARM payload.
  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "Microsoft.Resources/resourceGroups" },
        { field = "tags.costcenter", exists = "false" },
      ]
    }
    then = { effect = "deny" }
  })

  # No parameters this time — the rule is fixed, nothing for the assignment to tune.
  parameters = jsonencode({})
}

# Assign the custom definition to our resource group — same shape as lab 109,
# but policy_definition_id now points at OUR definition, not a built-in.
resource "azurerm_resource_group_policy_assignment" "this" {
  name                 = "require-costcenter-rg"
  resource_group_id    = azurerm_resource_group.this.id
  policy_definition_id = azurerm_policy_definition.require_costcenter.id
  display_name         = "Require costcenter tag"
  description          = "Deny resource groups missing a costcenter tag."
}

# Output: the custom definition's ID (contains the subscription scope + name).
output "definition_id" { value = azurerm_policy_definition.require_costcenter.id }
