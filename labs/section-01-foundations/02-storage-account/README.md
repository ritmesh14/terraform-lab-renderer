# 02 — Azure Storage Account

Your first real resource. Create a resource group and a general-purpose v2 storage
account, and learn how names, locals and random suffixes work together. This lab also
teaches the `random` provider: the suffix is saved in Terraform state, so every
plan/apply is stable and nothing gets replaced.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-storage-foundation` | Container for the lab |
| `random_string.suffix` | — | 6-char lowercase suffix, stored in state |
| `azurerm_storage_account.this` | `stfoundation<suffix>` | Standard tier, LRS, TLS 1.2, private blobs |

## Commands

Prerequisite: sign in to Azure first (`az login`), or export the `ARM_*` variables from
lab 01.

```bash
cd section-01-foundations/02-storage-account
terraform init
terraform plan
terraform apply
terraform output storage_account_name
terraform output primary_blob_endpoint
terraform destroy
```

## What to see in the Azure portal

Open [portal.azure.com](https://portal.azure.com) → **Resource groups** →
`rg-storage-foundation`. You should see:

- The storage account named `stfoundation` plus 6 random characters (click it →
  **Overview** shows Location `East US`, Performance `Standard`, Replication
  `Locally-redundant storage (LRS)`).
- Under **Security + networking → Networking**, *Public network access* is enabled but
  *Allow Blob anonymous access* is disabled (that is `allow_nested_items_to_be_public
  = false` at work).

## Key concepts / gotchas

- Storage account names are **globally unique across all of Azure**, lowercase, 3–24
  chars, alphanumerics only. We derive the name from a prefix + random suffix.
- `azurerm_resource_group` is the almost-always-first resource in any Azure config.
- `locals` hold derived values in one place: change `rg_name` or `region` there and
  everything follows.
- `random_string` is *stateful*: unlike hashing a timestamp, the suffix never changes
  between runs, so the storage account is not recreated every apply.
- `LRS` = 3 copies in one datacenter (cheapest); `Standard` tier = disk-based (vs
  Premium's SSD).