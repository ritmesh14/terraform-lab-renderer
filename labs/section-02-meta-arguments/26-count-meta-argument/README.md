# Lab 26 — The `count` meta-argument

`count` creates N copies of a resource. Each copy is addressed as `resource.name[0]`,
`resource.name[1]`, etc. Use `count` when the copies are **identical and indexed**.

This lab makes three storage containers (`data-0`, `data-1`, `data-2`) from one block.

```hcl
resource "azurerm_storage_container" "data" {
  count  = 3
  name   = "data-${count.index}"
  ...
}
```

## What it creates

| Terraform resource              | Azure name                       | Notes                     |
| ------------------------------- | -------------------------------- | ------------------------- |
| `azurerm_resource_group.this`   | Resource group `rg-count-meta`   | 1, holds everything below |
| `azurerm_storage_account.this`  | Storage account `stcount<rand>`  | 1, globally unique name   |
| `azurerm_storage_container.data`| Blob containers `data-0`..`data-2`| **x3 via `count`**        |
| `random_string.suffix`          | (no Azure resource)              | keeps the name stable     |

## Commands

```bash
cd 26-count-meta-argument
terraform init
terraform plan
terraform apply
terraform output container_names
terraform destroy
```

(Requires `az login` first if you have not authenticated the Azure CLI yet.)

## What to see in the Azure portal

- Resource group `rg-count-meta` → the storage account `stcount<random>` →
  **Storage browser → Blob containers**: you should see `data-0`, `data-1`, `data-2`,
  all with access type *Private*.
- Run `terraform output container_names` and compare — the same three names.

## Key concepts / gotchas

- `count.index` is the loop counter (0-based); use it in names and expressions.
- A `count` resource becomes a **list** in state: reference instances with
  `azurerm_storage_container.data[0]` or gather all with `[*]` (splat).
- `count` is best when copies are identical; if each copy needs different settings,
  prefer `for_each` (lab 28).
- Removing an item from the middle of a counted list makes Terraform recreate every
  instance after it, because indexes shift — another reason `for_each` is often safer.
- `random_string` is saved in state, so the storage account name stays stable across
  plans (an `md5(timestamp())` name would change every run and force replacement).
