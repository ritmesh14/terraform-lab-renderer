# Lab 28 — The `for_each` meta-argument

`for_each` creates one resource per **element of a set or map**. Each copy is addressed
by its key (`resource.name["key"]`). Prefer `for_each` over `count` when copies differ
in their configuration and are best addressed by a meaningful key.

This lab creates three containers named after a set of stages: `dev`, `stg`, `prod`.

## What it creates

| Terraform resource                | Azure name                       | Notes                                  |
| --------------------------------- | -------------------------------- | -------------------------------------- |
| `azurerm_resource_group.this`     | Resource group `rg-foreach-meta` | 1                                      |
| `azurerm_storage_account.this`    | Storage account `stforeach<rand>`| 1                                      |
| `azurerm_storage_container.stage` | Blob containers `dev`, `stg`, `prod` | **x3 via `for_each` over a `toset()`** |
| `random_string.suffix`            | (no Azure resource)              | stable unique name suffix              |

## Commands

```bash
cd 28-for-each-meta-argument
terraform init
terraform plan
terraform apply
terraform output containers
terraform destroy
```

(Requires `az login` first if you have not authenticated the Azure CLI yet.)

## What to see in the Azure portal

- Resource group `rg-foreach-meta` → storage account `stforeach<random>` →
  **Storage browser → Blob containers**: three containers named exactly `dev`,
  `stg`, `prod` — not `0`, `1`, `2`.
- `terraform output containers` prints the three keys of the for_each map.

## Key concepts / gotchas

- `toset(["dev", "stg", "prod"])` converts a list into a **set** (unique, unordered),
  which is a valid `for_each` collection. With a set, `each.key` and `each.value`
  are the same string.
- Instances are addressed by key, not index: `azurerm_storage_container.stage["dev"]`.
- Removing `"stg"` from the set destroys only that container — unlike `count`, where
  removing a middle item shifts every later index and forces recreation.
- `for_each` also accepts a **map**, which is how you give each instance different
  settings (see lab 33).
- The output uses `keys(...)` because a for_each resource is a map, not a list.
