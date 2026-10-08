# Lab 109 — Landing Zone: assign a BUILT-IN Azure Policy.
#  - data.azurerm_policy_definition looks up a built-in by display name.
#  - azurerm_resource_group_policy_assignment assigns it at the RG scope, passing
#    parameters (e.g. allowed storage SKUs) as JSON. Non-compliant deploys are denied.
# The scope the policy will police.
resource "azurerm_resource_group" "this" {
  name     = "rg-lz-policy"
  location = "eastus"
}

# Data source: fetches the BUILT-IN policy definition (Microsoft maintains it) by its
# display name, so we get the right definition ID without hardcoding a GUID.
# Built-in: allowed storage account SKUs (definition id is fixed per environment;
# use the data source to look it up by display name).
data "azurerm_policy_definition" "allowed_storage_skus" {
  display_name = "Allowed storage account SKUs"
}

# Assignment = "enforce that definition at THIS scope". The parameters are passed as
# JSON (the policy's contract). With a deny effect (this built-in's default), creating
# a storage account with any other SKU is refused — e.g. Standard_ZRS or Premium_LRS.
resource "azurerm_resource_group_policy_assignment" "allowed_storage_skus" {
  name                 = "allowed-storage-skus"
  resource_group_id    = azurerm_resource_group.this.id                         # the enforcement scope
  policy_definition_id = data.azurerm_policy_definition.allowed_storage_skus.id # the rule
  description          = "Restrict storage SKUs in the landing zone."
  display_name         = "Allowed storage account SKUs"

  # jsonencode turns this HCL map into the JSON string the policy API expects.
  # `listOfAllowedSKUs` is the parameter name defined by this particular built-in.
  parameters = jsonencode({
    listOfAllowedSKUs = {
      value = ["Standard_LRS", "Standard_GRS"]
    }
  })
}

# Output: the assignment's Azure ID (scope + assignment name encoded in the path).
output "assignment_id" { value = azurerm_resource_group_policy_assignment.allowed_storage_skus.id }
