# Lab 115 — Deploying to multiple environments

Drive environment differences purely through tfvars. One configuration, two variable
files (`dev.tfvars`, `prod.tfvars`). Nothing about "dev" or "prod" is hard-coded in
the resource blocks — the same `main.tf` builds either, depending only on the inputs
you pass on the command line.

## What it creates / does

| Terraform resource | Azure name | Notes |
|---|---|---|
| `random_string.suffix` | (not an Azure resource) | 6 random lowercase chars, stored in state for stability |
| `azurerm_resource_group.this` | `rg-multi-env-dev` or `rg-multi-env-prod` | Name built by interpolating `var.environment` |
| `azurerm_storage_account.this` | `st<env><suffix>` | Replication is `GRS` for prod, `LRS` otherwise (a ternary in code) |

Variable files:

| Variable | dev.tfvars | prod.tfvars |
|---|---|---|
| `environment` | `dev` | `prod` |
| `location` | `eastus` | `westeurope` |
| `tags` | `env=dev`, `managedby=terraform` | adds `costcenter=cc-200` |

## Commands

```bash
# Prerequisite: az login
cd 115-multiple-environments
terraform init
terraform plan  -var-file=dev.tfvars     # preview the dev stack
terraform apply -var-file=dev.tfvars     # create dev
terraform output replication             # expect "LRS"

terraform plan  -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
terraform output replication             # expect "GRS"

terraform destroy -var-file=dev.tfvars   # destroy needs the same var-file,
terraform destroy -var-file=prod.tfvars  # or it plans against different names!
```

## What to see

- Two separate resource groups in the portal, one per environment, each with its
  own tags (prod carries `costcenter`).
- `terraform output rg_name` differs per run: the outputs prove which var-file
  was applied.
- In the plan for prod: `account_replication_type = "GRS"`; for dev: `"LRS"` —
  the ternary in code picking per-environment settings.

## Key concepts / gotchas

- **tfvars = the classic way to split environments.** One codebase, `-var-file=`
  selects the environment. Costs nothing in code complexity — but note the state
  file is still *local and single*: both environments land in the same
  `terraform.tfstate` here. Workspaces (lab 116) and separate backends (lab 119)
  fix that.
- **Required variables have no defaults**, so forgetting `-var-file` makes
  Terraform prompt/fail instead of silently building the wrong environment.
- **The ternary pattern** `var.environment == "prod" ? "GRS" : "LRS"` encodes a
  cost/reliability decision in one line. Keep these small; big `if prod` trees
  in code get hard to review.
- **destroy needs the same var-file as apply** — otherwise Terraform computes
  *different* resource names (e.g. `rg-multi-env-dev` vs `rg-multi-env-prod`)
  and tries to destroy nothing.
- **Variables were declared twice** at one point (main.tf and variables.tf);
  Terraform rejects duplicate declarations, so `variables.tf` now holds only a
  note and everything lives in `main.tf`.
