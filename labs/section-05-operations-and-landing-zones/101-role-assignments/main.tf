# Lab 101 — RBAC role assignment via Terraform.
# azurerm_role_assignment grants a role (by name) to a principal on a scope.
# Here we grant the current signed-in user the built-in "Reader" role on a resource
# group. role_definition_name resolves to the built-in role's id automatically.
# Data source: reads facts about the identity Terraform is running as — the signed-in
# az cli user (or service principal). We need its `object_id` (Azure AD object ID of
# that user/SP), because a role assignment must say WHO gets the role.
data "azurerm_client_config" "current" {}

# Resource group the role will be granted on — the "scope" of the assignment.
resource "azurerm_resource_group" "this" {
  name     = "rg-rbac"
  location = "eastus"
}

# Grant the current user Reader on the resource group.
# RBAC assignment = WHO (principal_id) gets WHAT (role_definition_name) WHERE (scope).
#   - scope: this resource group (assignments can also target subscriptions/MGs/resources)
#   - role_definition_name: "Reader" resolves to the built-in role's definition ID
#     automatically (read-only: see everything, change nothing)
#   - principal_id: the object_id of the currently signed-in identity
resource "azurerm_role_assignment" "current_reader" {
  scope                = azurerm_resource_group.this.id
  role_definition_name = "Reader"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Output: the assignment's Azure ID — note it embeds a generated GUID, which is why
# re-applying an identical assignment elsewhere needs a new `name` argument.
output "assignment_id" { value = azurerm_role_assignment.current_reader.id }
