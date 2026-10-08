# Lab 109 — Landing Zone — Azure Policy

Assign a built-in policy at the landing-zone scope: "Allowed storage account SKUs".
A policy definition lives in `policyDefinition`, an assignment in `policyAssignment`.
This lab assigns a built-in definition (no need to author one).

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-lz-policy` | The policy's scope |
| `data.azurerm_policy_definition.allowed_storage_skus` | "Allowed storage account SKUs" | Built-in definition lookup |
| `azurerm_resource_group_policy_assignment.allowed_storage_skus` | `allowed-storage-skus` | Allowed: Standard_LRS, Standard_GRS |
| output `assignment_id` | — | Assignment's Azure ID |

## Commands

Prerequisite: `az login`. No tfvars needed.

```bash
cd 109-landing-zone-policy
terraform init
terraform plan
terraform apply
terraform output assignment_id
terraform destroy
```

## What to see in the Azure portal

Open resource group **rg-lz-policy** → **Overview → Policies** (or search
**Policy** in the portal):

- **Assignments** shows `allowed-storage-skus` scoped to this RG, definition
  "Allowed storage account SKUs".
- Click it → **Parameters** lists Standard_LRS and Standard_GRS.
- **Compliance**: any storage account created in the RG shows as compliant or
  non-compliant depending on its SKU.

## Key concepts / gotchas

- **Definition vs assignment**: the *definition* is the rule ("only these SKUs"),
  written once; the *assignment* binds it to a scope (here a resource group) with
  parameters. Same definition can be assigned at many scopes.
- **Built-in definitions are found via `data.azurerm_policy_definition`** by display
  name — you never copy a definition ID GUID by hand.
- **`parameters` must be JSON** — hence `jsonencode()`. The parameter names
  (`listOfAllowedSKUs`) are dictated by the specific policy definition, not by you.
- **Enforcement is at request time**: with the deny effect, a `az storage account
  create` with a disallowed SKU is refused outright — not flagged after the fact.
  (Other assignments use `audit`/`auditIfNotExists`, which only report non-compliance.)
- Policy is **independent of RBAC**: an admin with full rights can still be denied
  by policy; governance and permissions stack.
