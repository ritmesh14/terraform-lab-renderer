# Lab 29 — `for_each` over blobs

Use `for_each` with a **map** whose values describe each blob. Here we upload three
config files in one block, each with its own content.

## What it creates

| Terraform resource                | Azure name                      | Notes                                        |
| --------------------------------- | ------------------------------- | -------------------------------------------- |
| `azurerm_resource_group.this`     | Resource group `rg-foreach-blobs` | 1                                          |
| `azurerm_storage_account.this`    | Storage account `stblobfe<rand>`| 1                                            |
| `azurerm_storage_container.cfg`   | Blob container `config`         | 1, holds the blobs                           |
| `azurerm_storage_blob.file`       | Blobs `readme.md`, `app.json`, `note.txt` | **x3 via `for_each` over a map**   |
| `random_string.suffix`            | (no Azure resource)             | stable unique name suffix                    |

## Commands

```bash
cd 29-for-each-blobs
terraform init
terraform plan
terraform apply
terraform output blobs
terraform destroy
```

## What to see in the Azure portal

- Resource group `rg-foreach-blobs` → storage account → **Storage browser →
  Blob containers → `config`**: three blobs, each with the exact content from the
  `files` map in `main.tf` (open one to read it).

## Key concepts / gotchas

- A map's values can be rich objects, not just strings — here each value is the
  blob's content, and each key is the blob name (`each.key`) / content (`each.value`).
- Map keys with dots **must be quoted** (`"app.json"`), otherwise HCL reads the dots
  as attribute references.
- Changing a value in the map updates that blob in place; adding/removing an entry
  creates/destroys only that blob, because instances are keyed, not indexed.
- `source_content` uploads inline text; use `source` (a file path) for real files.
- The output uses `keys(...)` because a for_each resource is a map, not a list.
