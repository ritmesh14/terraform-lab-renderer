# 22 — Importing existing resources (advanced)

So far every resource was *created* by Terraform. In real life you inherit resources that
already exist in Azure and want to bring them under management without recreating them.
That's what `terraform import` does.

Two ways (Terraform ≥ 1.5):

## A. The CLI one-off

```bash
terraform import azurerm_storage_account.adopted \
  /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<name>
```

This writes the resource into state; you then write the matching `resource` block.

## B. The declarative `import` block (reusable, lives in code)

Declare both the `import` and the `resource`. Run `terraform plan` — Terraform reads the
existing resource, shows what it would record, and on `apply` binds the address.

## What it creates

Nothing new. The lab *adopts* an existing storage account:

| Terraform resource | Azure name | Notes |
|---|---|---|
| `data "azurerm_client_config" "current"` | — | Reads the subscription id |
| `import { to = azurerm_storage_account.adopted }` | — | Binds the existing resource |
| `azurerm_storage_account.adopted` | `stimportdemo<random>` (yours) | Pre-existing; not created |

## Run this lab

1. Create a storage account **outside** Terraform first:

   ```bash
   az group create -n rg-import-demo -l eastus
   az storage account create -n stimportdemo<random> -g rg-import-demo --sku Standard_LRS
   ```

2. Set the two variables (copy `terraform.tfvars.example` and put in your real names)
   and run:

   ```bash
   terraform init
   terraform plan     # Terraform imports the existing account, no changes
   terraform apply    # records it in state
   terraform destroy  # now Terraform CAN destroy it — it owns it
   ```

## What to see

- `terraform plan` shows **1 to import** and then, for the imported account, whatever
  differs from the `resource` block (often `min_tls_version` or
  `allow_nested_items_to_be_public` defaults that Azure set but the block doesn't
  specify).
- After `apply`, `terraform state list` shows `azurerm_storage_account.adopted` — the
  pre-existing account is now Terraform-managed.

## Key concepts / gotchas

- Import **only writes state** — it creates nothing and checks nothing. If your
  `resource` block doesn't match reality, the *next* plan shows the difference as
  changes Terraform wants to make.
- The import `id` is the **full Azure resource id**:
  `/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<name>`.
  Each Azure resource type has its own id shape — that's what the `data` block builds.
- The declarative `import {}` block (Terraform ≥ 1.5) is reviewable in version control;
  the CLI `terraform import` command is a one-off that only touches state.
- If the plan after import shows changes you *don't* want, either align the resource
  block with reality or let Terraform fix the drift — decide deliberately.
- `terraform destroy` after importing now **deletes the real storage account** —
  ownership has real consequences.