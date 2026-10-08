# Lab 39 — Data sources

`data` blocks **read** existing resources instead of creating them. This lab looks up an
existing resource group and uses its attributes to create a storage account — without
owning the resource group.

```hcl
data "azurerm_resource_group" "existing" {
  name = "rg-already-here"
}
```

Run it after creating a resource group named `rg-already-here` (lab 27 creates one you
could point at), or change the name to suit your subscription.

## What it creates

| Terraform resource                    | Azure name                        | Notes                                            |
| ------------------------------------- | --------------------------------- | ------------------------------------------------ |
| `data.azurerm_resource_group.existing`| (reads, creates nothing)          | the resource group you name in `existing_rg_name`|
| `random_string.suffix`                | (no Azure resource)               | stable unique name suffix                        |
| `azurerm_storage_account.this`        | Storage account `stdata<rand>`    | 1, created **inside the existing RG**            |

## Commands

```bash
cd 39-data-sources
az group create -n rg-already-here -l eastus   # prerequisite: the RG must exist
terraform init
terraform plan
terraform apply
terraform output rg_location
terraform destroy   # destroys ONLY the storage account, not the existing RG
```

## What to see in the Azure portal

- Open the resource group `rg-already-here`: it now contains a storage account
  `stdata<random>` (created by this lab) and nothing else was added — the group itself
  is not owned by Terraform.
- `terraform output rg_location` / `rg_tags` print attributes read from the group.

## Key concepts / gotchas

- `data` = read-only lookup; `resource` = create/manage. Terraform will never modify
  or delete a resource discovered through a `data` block.
- The lookup fails at plan time if the group does not exist — create it first
  (`az group create`) or point `existing_rg_name` at an RG you already have.
- Attributes flow into the new resource: `resource_group_name` and `location` come
  from the data source, so the storage account lands in the right place without you
  hardcoding either.
- Because data-source values are already known, `rg_location` is visible in `plan`
  (unlike an apply-time attribute such as a new public IP).
- `terraform destroy` removes only what this config owns — the existing group
  survives.
