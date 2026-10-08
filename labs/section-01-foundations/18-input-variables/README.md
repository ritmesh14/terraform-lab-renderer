# 18 — Input variables

Variables parameterise a configuration. This lab recreates the storage account but makes
the location, name prefix and tier all variables with validation and sensible defaults.
Change the deployment without touching a single resource block.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-vars-foundation` | Region from `var.location` |
| `azurerm_storage_account.this` | `<name_prefix><suffix>` | Tier from `var.tier` |

## Commands

Prerequisite: `az login` (or the `ARM_*` variables from lab 01).

```bash
cd section-01-foundations/18-input-variables
terraform init
terraform plan                                  # all defaults
terraform apply -var "location=westeurope" -var "tier=Premium"
TF_VAR_location=westus2 terraform plan          # env-var style
terraform destroy
```

Try breaking a validation to see it fail fast:

```bash
terraform plan -var "name_prefix=BAD_NAME"   # rejected before any plan
```

## What to see

- With no overrides, the storage account is named `stvar` + 6 random characters in
  `eastus`, Standard tier.
- Validation failures appear immediately at plan time with your `error_message` text.
- `terraform apply` prompts for any variable that has neither a default nor a supplied
  value (none here — all three have defaults).

## What to see in the Azure portal

**Resource groups** → `rg-vars-foundation` → the storage account starting with
`stvar`. **Overview** shows the region you passed via `-var` and the tier
(Standard/Premium) under *Performance*.

## Key concepts / gotchas

- A variable has four knobs: `type`, `default`, `description`, `validation` — and its
  value is referenced as `var.<name>`.
- **Precedence** (highest wins): `-var` / `-var-file` flags → auto-loaded
  `terraform.tfvars` and `*.auto.tfvars` → `TF_VAR_<name>` environment variables →
  the `default` in the block.
- `validation` blocks run **before plan**; `can(regex(...))` is the common guard for
  format checks, `contains([...])` for enum-style choices.
- `name_prefix` is deliberately limited to 3–18 characters so `prefix + 6-char suffix`
  stays within Azure's 24-character storage account name limit.
- Variables make the config reusable across environments; locals (lab 07) compute
  values *inside* it — different jobs, used together.