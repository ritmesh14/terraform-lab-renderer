# Lab 102 — Locking resources with Terraform

A management lock (`CanNotDelete` / `ReadOnly`) protects resources from accidental
deletion. This lab puts a `CanNotDelete` lock on a storage account so `terraform destroy`
(or a portal click) refuses to remove it.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `random_string.suffix` | — | 6 chars for the globally-unique storage name |
| `azurerm_resource_group.this` | `rg-locks` | eastus |
| `azurerm_storage_account.this` | `stlock<suffix>` | Standard LRS |
| `azurerm_management_lock.st` | `do-not-delete` | `CanNotDelete` on the storage account |
| output `lock_id` | — | Azure ID of the lock itself |

## Commands

Prerequisite: `az login`. No tfvars needed.

```bash
cd 102-resource-locks
terraform init
terraform plan
terraform apply
terraform output lock_id
terraform destroy
```

## What to see in the Azure portal

Open resource group **rg-locks** → storage account `stlock<suffix>` →
**Settings → Locks**: you'll see `do-not-delete` with lock type **Delete**
(that's how Azure displays `CanNotDelete`). Resource group **rg-locks → Locks**
is empty — the lock is scoped to the storage account, not the group.

## Key concepts / gotchas

- **Locks are independent of RBAC.** Even a subscription Owner gets
  `AuthorizationFailed`/`ScopeLocked` when deleting a locked resource; only removing
  the lock helps.
- **`CanNotDelete` vs `ReadOnly`**: CanNotDelete allows reads/writes but blocks
  delete; ReadOnly blocks writes and deletes too (and breaks many portal operations).
- **The lock's protection bites *outside* Terraform.** A plain
  `az group delete -n rg-locks` or a portal delete fails with `ScopeLocked` —
  Azure refuses to delete the storage account while the lock exists.
  `terraform destroy` still succeeds, because Terraform destroys the
  `azurerm_management_lock` resource *before* the storage account it points at
  (dependency order) — which is also why a lock that lives only in Terraform state
  protects nothing while the state is being applied.
- Locks **inherit downward** from their scope: a lock on a subscription or resource
  group protects everything inside it.
- Locks are not "backup" — they stop deletion, but data can still be overwritten.
  Pair locks with backups/soft-delete for real protection.
