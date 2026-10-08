# 19 — Variable definition file (tfvars)

`terraform.tfvars` (or `*.auto.tfvars`) supplies variable values without cluttering the
CLI. This lab reuses lab 18's variables but declares them **without defaults**, so
Terraform refuses to run until the tfvars file (or a `-var` flag) provides them — the
standard "code defines shape, files define values" split.

```bash
terraform plan                      # uses terraform.tfvars
terraform plan -var-file=dev.tfvars # explicit file
```

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-tfvars-foundation` | Region from tfvars |
| `azurerm_storage_account.this` | `sttfvar<suffix>` | Values all come from `terraform.tfvars` |

## Commands

Prerequisite: `az login` (or the `ARM_*` variables from lab 01).

```bash
cd section-01-foundations/19-variable-definition-file
terraform init
terraform plan                       # reads terraform.tfvars automatically
terraform apply
terraform destroy
```

Try the explicit-file form and the "missing value" error:

```bash
terraform plan -var-file=dev.tfvars      # any file you create
terraform plan -var-file=missing.tfvars  # Terraform errors: variables not supplied
```

## What to see in the Azure portal

**Resource groups** → `rg-tfvars-foundation` → the storage account starting with
`sttfvar`. Its region (East US) and performance (Standard) are exactly the three lines
in `terraform.tfvars` — proof the file drove the deployment.

## Key concepts / gotchas

- `terraform.tfvars` is **auto-loaded by name**; `*.auto.tfvars` files are too
  (alphabetical order). Any other file needs `-var-file=path`.
- Variables declared **without a default** are *required*: plan/apply fails with
  "Required variable not set" unless tfvars, `-var`, or `TF_VAR_*` supplies it.
- Typical layout: one default `terraform.tfvars` plus per-environment files
  (`dev.tfvars`, `prod.tfvars`) passed with `-var-file`.
- **Never commit real secrets** in tfvars — use `terraform.tfvars.example` checked in,
  and `.tfvars` in `.gitignore` (lab 17 and 20 follow that pattern).
- Precedence recap: `-var`/`-var-file` flags beat auto-loaded tfvars, which beat
  `TF_VAR_*` env vars, which beat in-code defaults.