# Lab 114 — Inspecting the initial code base

Before refactoring, study what you have. This lab is a copy of section-01's storage
account (lab 115) to serve as the "initial code base". The point: never change code
you don't understand. Read `main.tf` line by line first — it builds one resource
group, one storage account, and a small random string used to make the storage
account's name unique.

## What it creates / does

| Terraform resource | Azure name | Notes |
|---|---|---|
| `random_string.suffix` | (not an Azure resource) | 6 random lowercase characters, stored in state so it never changes on later plans |
| `azurerm_resource_group.this` | Resource group `rg-inspect` | Container for everything else |
| `azurerm_storage_account.this` | Storage account `stinspect<suffix>` | Standard LRS; name must be globally unique, 3–24 lowercase letters/digits |

## Commands

```bash
# Prerequisite: az login   (Terraform uses your Azure CLI session by default)
cd 114-inspect-codebase
terraform init     # downloads the azurerm + random providers
terraform plan     # preview the changes Terraform *would* make
terraform apply    # create them
terraform output   # show declared outputs (storage_name)
terraform destroy  # clean up
```

Also useful when inspecting code you didn't write:

```bash
terraform plan      # see the planned changes
terraform graph     # visualise the dependency graph
terraform state list   # after apply: every resource address Terraform tracks
```

`terraform graph` outputs DOT; pipe to Graphviz: `terraform graph | dot -Tsvg > graph.svg`.
(No Graphviz installed? The raw text output already shows the arrows.)

## What to see

- In the plan: two resources to add (`+`), with `azurerm_storage_account`
  depending on the resource group — the reference
  `azurerm_resource_group.this.name` creates that ordering.
- In the Azure portal: Resource groups → `rg-inspect` → one storage account.
- `terraform output storage_name` prints the actual (suffix-extended) account name.

## Key concepts / gotchas

- **Plan before apply.** `terraform plan` is a read-only diff against the state
  file — get in the habit of reading it before every apply.
- **References create dependencies.** Terraform orders operations from
  `resource_a.attr` → `resource_b` references, so the storage account is created
  after the group without any explicit "depends_on".
- **State makes random values stable.** `random_string` is saved in state; a
  computed-only value like `md5(timestamp())` would churn every plan and force
  pointless replacements.
- **`terraform graph` is a code-reading tool**, not a required step — it renders
  the same dependency structure you see when reading the references.
- **Naming constraints bite.** Azure storage account names allow only lowercase
  letters and digits (3–24 chars) — hence the `lower()` and no dashes in `st_name`.
