# Lab 27 — Multiple containers (assignment)

Self-check: drive `count` from a variable so the number of containers is configurable
without editing code. Try `terraform apply -var=container_count=5`.

## What it creates

| Terraform resource               | Azure name                      | Notes                              |
| -------------------------------- | ------------------------------- | ---------------------------------- |
| `azurerm_resource_group.this`    | Resource group `rg-multi-containers` | 1                              |
| `azurerm_storage_account.this`   | Storage account `stcont<rand>`  | 1, lowercase + random suffix       |
| `azurerm_storage_container.data` | Blob containers `tier-0`..`tier-N` | **x `container_count` via count** |
| `random_string.suffix`           | (no Azure resource)             | stable unique name suffix          |

## Commands

```bash
cd 27-multiple-containers
terraform init
terraform plan -var=container_count=5
terraform apply -var=container_count=5
terraform output container_names
terraform destroy
```

The default is `container_count = 3` (declared in `main.tf` with a `validation` block
that keeps the value between 1 and 10).

## What to see in the Azure portal

- Resource group `rg-multi-containers` → storage account `stcont<random>` →
  **Storage browser → Blob containers**: exactly as many `tier-N` containers as you
  asked for, numbered from 0.
- `terraform output count` prints the number of containers that were created.

## Key concepts / gotchas

- `count = var.container_count` — a meta-argument can be any number expression, not
  just a literal, so one variable now controls the whole fan-out.
- The `validation` block inside `variable` catches bad input (`0`, `-1`, `11`) at
  **plan time** instead of producing confusing Azure errors.
- Changing the variable scales the number of containers up or down; instances are
  index-addressed, so shrinking removes the highest indexes.
- Outputs use `length(...)` on the count-created list and `[*]` (splat) to collect
  every container name.
