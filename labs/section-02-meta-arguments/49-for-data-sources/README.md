# Lab 49 — `for_each` over a data source (advanced)

`for_each` can iterate over the results of a `data` block. Pass the names of resource
groups that already exist in your subscription to `rg_names`; Terraform opens one
`data "azurerm_resource_group"` per name (`for_each`) and reads its attributes. It's a
governance pattern: discovery → bulk action.

> The `data "azurerm_resource_groups"` list data source was removed in azurerm 3.x, so
> discovery here is driven by the names you pass in rather than a subscription-wide
> listing — the `for_each`-over-data pattern is unchanged.

> This lab only **reads and reports** on existing resource groups — `data` blocks
> create and change nothing. Passing names that don't exist fails at plan time,
> which makes a wrong list safe to discover.

## What it creates

| Terraform resource                    | Azure name                          | Notes                                     |
| ------------------------------------- | ----------------------------------- | ----------------------------------------- |
| `data.azurerm_resource_group.each`    | (reads, creates nothing)            | **one per name in `rg_names` via `for_each`** |
| (resources)                           | —                                   | none — this lab is read-only              |

## Commands

```bash
cd 49-for-data-sources
terraform init
terraform plan \
  -var='rg_names=["rg-already-here","rg-multi-subnets"]'
terraform apply \
  -var='rg_names=["rg-already-here","rg-multi-subnets"]'
terraform output discovered_rg_ids
```

The names must already exist (lab 30's `rg-multi-subnets` works if you kept it). An
empty `rg_names` (the default) is a no-op.

## What to see in the Azure portal

- Nothing changes — that is the point. The outputs report the number, names and full
  resource IDs of the groups you listed; `terraform output discovered_rg_ids` matches
  the IDs you'd see in each resource group's **Overview** page.

## Key concepts / gotchas

- `data` blocks can also fan out with `for_each`: one read per key, each addressed as
  `data.azurerm_resource_group.each["rg-already-here"]`.
- Data sources are read-only: Terraform plans no changes to the discovered groups.
- A wrong (nonexistent) name fails at plan time — data lookups happen before any
  change is proposed, which makes this a safe discovery step.
- The `for` expression `[for rg in data.azurerm_resource_group.each : rg.id]` walks
  the data-source map and collects attributes — the standard way to summarize a fan-out.
- Real bulk "governance" work (tagging, locks, RBAC) would add a resource driven by
  these discovered values — this lab stops one step before that.
