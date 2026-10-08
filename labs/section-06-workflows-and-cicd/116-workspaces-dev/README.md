# Lab 116 — Terraform workspaces — dev environment

Workspaces let one configuration manage several state files (e.g. dev, stg, prod).
The `terraform.workspace` built-in value picks names/tiers per workspace: the code
reads `terraform.workspace` and branches on it, so switching workspace switches
which Azure resources you manage — without editing any code.

## What it creates / does

| Terraform resource | Azure name | Notes |
|---|---|---|
| `random_string.suffix` | (not an Azure resource) | 6 random lowercase chars, stored in each workspace's state |
| `azurerm_resource_group.this` | `rg-ws-<workspace>` | e.g. `rg-ws-dev`, `rg-ws-prod` |
| `azurerm_storage_account.this` | `stws<workspace><suffix>` | GRS in the `prod` workspace, LRS otherwise (ternary on `terraform.workspace`) |

Each workspace keeps its **own state file** locally at
`terraform.tfstate.d/<workspace-name>/terraform.tfstate` — that is the whole trick:
same code, isolated states.

## Commands

```bash
# Prerequisite: az login
cd 116-workspaces-dev
terraform init
terraform workspace new dev      # create the "dev" workspace (own state file)
terraform workspace new prod     # create the "prod" workspace
terraform workspace select dev   # switch into it
terraform apply                  # builds rg-ws-dev / stwsdev...
terraform workspace select prod
terraform apply                  # builds rg-ws-prod / stwsprod...
terraform workspace list         # show all workspaces, * marks current
terraform workspace show         # print current workspace name
terraform destroy                # destroys only the *selected* workspace's resources
```

## What to see

- `terraform.tfstate.d/dev/` and `terraform.tfstate.d/prod/` on disk — one state
  file per workspace.
- Two resource groups in the portal (`rg-ws-dev`, `rg-ws-prod`), each tagged
  `environment = <workspace>`.
- `terraform output replication` after selecting `prod`: `GRS`; under `dev`: `LRS`
  — the same code, branching on the workspace.

## Key concepts / gotchas

- **A workspace is a named state file, not an environment directory.** Switching
  with `workspace select` changes which state you plan/apply against — check the
  `workspace list` output (the `*`) before running anything destructive.
- **`terraform.workspace` is the only lever.** Locals branch on it for names and
  SKU; the `prod` ternary is the "per-workspace settings" idiom.
- **Best for same-shape environments.** All workspaces run the *same* code with
  the same providers. If prod needs genuinely different resources, use separate
  directories/backends (lab 119) instead.
- **No backend block here**, so workspace state lives locally; a remote backend
  (lab 119) keys state per workspace the same way — often the real production use
  of workspaces.
- **The default workspace** (`default`) exists even if you never created one —
  don't let it become a dumping ground for half-tested applies.
