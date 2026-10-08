# 14 — Output values

`output` blocks expose values to the user (printed after `apply`) and to other
configurations (via `terraform output` or remote state). This lab creates a storage
account and outputs several attributes — including a **sensitive** primary key, which
Terraform masks in logs.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-output-foundation` | Container for the lab |
| `azurerm_storage_account.this` | `stout<suffix>` | Standard, LRS |

## Commands

Prerequisite: `az login` (or the `ARM_*` variables from lab 01).

```bash
cd section-01-foundations/14-output-values
terraform init
terraform apply
terraform output                      # all outputs
terraform output storage_account_name
terraform output primary_access_key   # sensitive outputs print on demand
terraform destroy
```

## What to see

- In the `terraform apply` summary you will see `storage_account_name`,
  `primary_blob_endpoint`, and `primary_access_key = (sensitive value)`.
- `terraform output primary_access_key` is how you retrieve the masked value when you
  actually need it.
- The `primary_blob_endpoint` is a URL like `https://stout<suffix>.blob.core.windows.net/`.

## Key concepts / gotchas

- Outputs are declared in `outputs.tf` and reference resource attributes — they are
  read-only views, never inputs.
- `sensitive = true` only **masks** the value in logs. The value is still stored in the
  state file in plain text, so protect state files (and use a secrets manager for
  real deployments).
- `description` documents an output for humans (and module consumers); it appears with
  `terraform output` help and in the registry.
- Outputs become inputs for other configs when this folder is used as a module —
  `module.<name>.<output>` on the caller side.
- The storage account name comes from `random_string`, so outputs are also a good way
  to *discover* names you can't predict (globally unique suffixes).