# Lab 110 — Custom Azure Policy definition + assignment (advanced)

Lab 109 assigned a **built-in** policy. This lab authors a **custom** policy definition
(`azurerm_policy_definition`) — "deny resource groups without a `costcenter` tag" — and
assigns it at a resource group scope. Custom policies express rules the built-ins don't
cover.

The policy rule uses `policyRule` JSON: a `deny` effect when `tags.costcenter` is missing.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-custom-policy` | Tagged `costcenter=cc-100` so it complies |
| `azurerm_policy_definition.require_costcenter` | "Require a costcenter tag on resource groups" | Custom, `deny` effect, subscription scope |
| `azurerm_resource_group_policy_assignment.this` | `require-costcenter-rg` | Bound to `rg-custom-policy` |
| output `definition_id` | — | Custom definition ID |

## Commands

Prerequisite: `az login`. No tfvars needed.

```bash
cd 110-custom-policy-definition
terraform init
terraform plan
terraform apply
terraform output definition_id
terraform destroy
```

## What to see in the Azure portal

- Search **Policy → Definitions**: filter Definition type = **Custom** — you'll see
  "Require a costcenter tag on resource groups" (stored at your subscription).
- Open resource group **rg-custom-policy** → **Overview → Policies → Assignments**:
  `require-costcenter-rg` bound to this RG, with parameters empty.
- **Compliance**: `rg-custom-policy` shows **Compliant** (it has the tag). A group
  without the tag would show **Non-compliant** — and with the `deny` effect, creating
  one is refused at submission time.

## Key concepts / gotchas

- **A custom definition is `policy_type = "Custom"`** and lives at the subscription
  (or management group) scope; `mode = "All"` makes the rule apply to any resource
  type the rule mentions.
- **Rule anatomy**: `if` describes when the rule matches (via `field` conditions on
  the ARM request payload), `then.effect` decides the outcome — `deny` refuses,
  `audit` merely flags. `allOf` = logical AND.
- **JSON-in-HCL**: policy bodies are JSON strings, so `jsonencode()` builds them;
  this is the same trick lab 109 used for `parameters`.
- **Ordering matters**: the demo RG is created *with* the tag, so it passes its own
  policy. Applying the assignment to an untagged group would deny updates to that group
  in later applies (policy evaluation can bite Terraform itself).
- Custom definitions can be deleted with Terraform only after their assignments are
  removed (Azure refuses deleting an assigned definition).
