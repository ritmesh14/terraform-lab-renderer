# Lab 119 — Azure Storage for the state file

By now every lab has produced a local `terraform.tfstate` — a single file on your
machine that Terraform reads and rewrites. That breaks the moment a team or a
pipeline is involved: no sharing, no locking, no backups. This lab moves state into
an Azure Storage account blob. Two parts, run in order.

## What it creates / does

**Part A (`bootstrap/`)** — creates the backend itself, once:

| Terraform resource | Azure name | Notes |
|---|---|---|
| `random_string.suffix` | (not an Azure resource) | Makes the storage account name globally unique |
| `azurerm_resource_group.this` | `rg-tfstate` | Holds the state storage |
| `azurerm_storage_account.this` | `sttfstate<suffix>` | TLS 1.2 minimum; blobs can't be made public |
| `azurerm_storage_container.tfstate` | Blob container `tfstate` | One state file = one blob inside it |

**Part B (`app/`)** — a config that *uses* that backend via a `backend "azurerm"`
block (inline in `main.tf`; `backend.tf` is a placeholder note). It creates just
`azurerm_resource_group.app` (`rg-remote-state-app`) to prove the backend works.

## Commands

```bash
# Prerequisite: az login
cd 119-remote-state-storage/bootstrap
terraform init
terraform apply                          # creates rg, storage account, container
terraform output                         # copy resource_group_name / storage_account_name / container_name

cd ../app
terraform init -backend-config="resource_group_name=rg-tfstate" \
              -backend-config="storage_account_name=sttfstate<suffix>" \
              -backend-config="container_name=tfstate" \
              -backend-config="key=app.tfstate"
terraform apply
terraform destroy                        # destroys the app resources (not the backend)
```

## What to see

- In the portal: Resource groups → `rg-tfstate` → the storage account →
  Containers → `tfstate` → a blob named `app.tfstate` after Part B's apply.
- In `app/`: no `terraform.tfstate` on disk anymore — state now lives in Azure,
  shared and locked. (`.terraform/terraform.tfstate` holds only backend config.)
- Try two applies in parallel from two terminals: the second waits or fails —
  **state locking** (Azure blob leases) is preventing corruption.

## Key concepts / gotchas

- **The bootstrap chicken-and-egg.** The backend must exist before any config can
  point at it, and `backend` blocks can't reference resources — so the bootstrap
  config deliberately keeps its state local and runs once, by hand.
- **`key` is the filename inside the container.** Different configs (or
  environments) need different keys (`app.tfstate`, `app.prod.tfstate`) or they
  would overwrite each other's state.
- **Pass backend values with `-backend-config=...`** rather than editing the
  placeholder values inline — the file stays shareable and per-user values
  (account names with random suffixes) stay out of the repo.
- **Remote state gives you locking + sharing + durability.** Local state has
  none of those: two `applies` racing locally corrupt the file; a lost laptop
  loses the infrastructure record.
- **Never delete the state container** (or worse, the whole storage account)
  casually — Terraform's memory of every resource lives there. Back it up /
  version it before risky operations.
