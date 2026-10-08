# Lab 118 — Making changes to our code

Iterate safely: change code → `terraform plan` → review the diff → `apply`. This lab
takes the storage account and adds a container + blob. The blob's content is set by
`source_content` in code, so editing that string and re-planning shows exactly what
"making a change" looks like to Terraform.

## What it creates / does

| Terraform resource | Azure name | Notes |
|---|---|---|
| `random_string.suffix` | (not an Azure resource) | 6 random chars, stored in state |
| `azurerm_resource_group.this` | `rg-changes` | Container for the stack |
| `azurerm_storage_account.this` | `stchange<suffix>` | Standard LRS |
| `azurerm_storage_container.data` | Blob container `data` | Private access |
| `azurerm_storage_blob.readme` | Blob `readme.txt` in container `data` | Content comes from `source_content` in code |

## Commands

```bash
# Prerequisite: az login
cd 118-making-changes
terraform init
terraform plan          # first run: + container and + blob (account unchanged)
terraform apply
terraform output blob_url

# now edit source_content in main.tf, then:
terraform plan          # shows ~ azurerm_storage_blob.readme  (in-place update)
terraform apply
terraform destroy       # clean up
```

## What to see

- First plan: the container and blob appear as `+` additions, while the storage
  account and resource group show nothing — untouched attributes are no-ops.
- After editing `source_content` to new text: the plan marks
  `~ azurerm_storage_blob.readme` and shows `source_content: "old" -> "new"` —
  an **in-place update**, not a destroy/create.
- Open the `blob_url` output in a browser to confirm the new text landed.

## Key concepts / gotchas

- **Plan is the review step.** In a real repo the plan output is what a teammate
  reviews on a pull request — the diff tells you exactly what will change before
  anything touches Azure.
- **In-place vs replacement.** A `~` in the plan is an update in place; a
  `-/+` means destroy-and-recreate (forces_replacement attributes). Read that
  symbol before you apply.
- **Some changes need no apply at all.** Output-only edits apply instantly;
  provider-only edits happen at plan time.
- **State is the diff baseline.** Terraform compares code to state (and state to
  real Azure) — which is why the random suffix never changes between plans.
- **Content as code.** `source_content` makes the file's *contents* part of the
  infrastructure review; anything you edit in code shows up in the next plan.
