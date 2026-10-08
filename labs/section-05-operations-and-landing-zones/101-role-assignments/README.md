# Lab 101 — Role assignments via Terraform

`azurerm_role_assignment` grants an Azure RBAC role to a principal on a scope. This lab
creates a resource group (`rg-rbac`) and grants the **currently signed-in identity**
(the one behind `az login`) the built-in **Reader** role on that resource group.

Use a `data "azurerm_client_config"` data source to look up the current principal's
object ID, and address built-in roles by name via `role_definition_name`.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `data.azurerm_client_config.current` | — | Reads the current identity's `object_id` |
| `azurerm_resource_group.this` | `rg-rbac` | The scope of the assignment |
| `azurerm_role_assignment.current_reader` | "Reader" assignment on `rg-rbac` | principal = you, role = Reader |
| output `assignment_id` | — | Azure assignment ID (contains a generated GUID) |

## Commands

Prerequisite: `az login` — the role is granted to *that* identity. No tfvars needed.

```bash
cd 101-role-assignments
terraform init
terraform plan
terraform apply
terraform output assignment_id
terraform destroy
```

## What to see in the Azure portal

Open resource group **rg-rbac** → **Access control (IAM)** → **Role assignments**.
You'll find **Reader** granted to your own user/account name. Click it to see the
assigned principal and that the scope is this resource group.

## Key concepts / gotchas

- An RBAC assignment has three parts: **principal** (who — a user, group, service
  principal or managed identity), **role definition** (what — Reader, Contributor, …),
  and **scope** (where — management group, subscription, resource group or resource).
- `role_definition_name = "Reader"` works for built-in roles; custom roles need
  `role_definition_id` (a full definition ID) instead.
- `data "azurerm_client_config"` is the standard trick to get *your own* object ID
  without hardcoding it.
- Role assignments can take a few minutes to become effective (Azure AD propagation).
- Terraform destroying the assignment only removes the grant — it never deletes the
  role definition (built-ins can't be deleted) or the principal.
