# Lab 53 — The `lifecycle` meta-argument

`lifecycle {}` changes how Terraform treats a resource over time:

- `create_before_destroy` — build the new version first, then tear down the old.
- `prevent_destroy` — refuse to destroy (safety guard for prod databases).
- `ignore_changes` — leave chosen attributes to drift (e.g. tags set by another tool).

This lab builds a storage account + container (a smaller, cheaper stand-in for the
web app you'll use later) and exercises `create_before_destroy` and `ignore_changes`.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-lifecycle` | folder for the lab |
| `azurerm_storage_account` | `stlife<6 random chars>` (lowercased) | `ignore_changes = [tags["owner"]]` |
| `azurerm_storage_container` | `lifecycle` | blob container, `create_before_destroy = true` |

## Commands

Prerequisite: `az login`.

```bash
cd 53-lifecycle
terraform init
terraform plan
terraform apply
terraform destroy
```

## What to see in the Azure portal

Resource group **rg-lifecycle**:

- **Storage account** `stlife...` → **Tags**: `owner = platform-team`. Edit the tag
  by hand in the portal, then run `terraform plan` again: Terraform reports
  **no changes** because `ignore_changes` lets that tag drift.
- **Containers** (under *Data storage*): the `lifecycle` container, private access.

## Key concepts / gotchas

- **When is `lifecycle` used?** — it's a meta-argument (like `depends_on`), valid on
  any `resource`/`data` block, and never changes what the resource *is*, only how
  Terraform treats it.
- **`ignore_changes = [tags["owner"]]`** — targets one map key, not all of `tags`;
  other tag keys are still managed. This is the standard fix for "another tool (Azure
  Policy, CI) keeps editing my resource".
- **`create_before_destroy`** — matters when the name forces a replace (rename
  something and apply): the new resource is created first, so there is no window
  where the resource doesn't exist. Without it, Terraform deletes first, then
  creates — which fails when the name is taken by the still-registered old resource.
- **`prevent_destroy`** (demonstrated in the header comment, not applied here) —
  would make `terraform destroy` fail loudly; use it on databases.
- Storage account names are globally unique, 3–24 chars, lowercase letters/digits
  only — that's why `lower()` + a random suffix.
