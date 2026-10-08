# Lab 106 — Landing Zone — storage deployment

App data storage in the data RG: a general-purpose v2 account with a couple of private
containers and TLS 1.2 enforced.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `random_string.suffix` | — | 6 chars making the account name unique |
| `azurerm_resource_group.data` | `rg-lz-data` | eastus |
| `azurerm_storage_account.app` | `stlzapp<suffix>` | Standard LRS, TLS 1.2, public access off |
| `azurerm_storage_container.uploads` | `uploads` | access type `private` |
| `azurerm_storage_container.archive` | `archive` | access type `private` |
| output `storage_name` | — | Account name for CLI/tests |

## Commands

Prerequisite: `az login`. No tfvars needed.

```bash
cd 106-landing-zone-storage
terraform init
terraform plan
terraform apply
terraform output storage_name
terraform destroy
```

## What to see in the Azure portal

Open resource group **rg-lz-data** → storage account `stlzapp<suffix>`:

- **Data storage → Containers**: `uploads` and `archive`, both with
  **Public access level: Private (no anonymous access)**.
- **Settings → Configuration**: "Allow Blob public access" is **Disabled**, and
  **Minimum TLS version** is **TLS 1.2**.

## Key concepts / gotchas

- **`allow_nested_items_to_be_public = false`** is account-level: it blocks anonymous
  access for every container/blob inside, even if someone later flips a container's
  setting in the portal. Terraform will also flip it back on the next apply.
- **`container_access_type = "private"`** is the per-container setting; private means
  access only via the account keys / SAS tokens / RBAC.
- Storage account **names are global** across all of Azure — the random suffix exists
  so `apply` never collides with someone else's account (and stays stable across runs
  because it's saved in state).
- **`min_tls_version = "TLS1_2"`** rejects old TLS handshakes; a common landing-zone
  baseline for every storage account.
- Containers are separate resources from the account: you can manage, import or
  destroy a container without touching the account.
