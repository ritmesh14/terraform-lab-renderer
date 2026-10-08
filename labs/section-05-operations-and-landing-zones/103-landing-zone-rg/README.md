# Lab 103 — Landing Zone — resource groups

The landing zone starts with three resource groups: network, data, and security. Keeping
them separate matches the Azure landing-zone pattern and lets you assign different teams.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.network` | `rg-app1-net` | VNet, subnets, NSGs go here (lab 104) |
| `azurerm_resource_group.data` | `rg-app1-data` | Storage (09), database (10) go here |
| `azurerm_resource_group.security` | `rg-app1-sec` | Key Vault (11) goes here |
| output `rg_names` | — | Map of the three names |

All three carry tags `landing_zone=app1` and `managedby=terraform`.

## Commands

Prerequisite: `az login`. Defaults need no tfvars; override with
`terraform apply -var landing_zone_name=app2` or a tfvars file.

```bash
cd 103-landing-zone-rg
terraform init
terraform plan
terraform apply
terraform output rg_names
terraform destroy
```

## What to see in the Azure portal

Filter the Resource groups list by the tag **landing_zone = app1**: you'll see
`rg-app1-net`, `rg-app1-data`, `rg-app1-sec`. Open any one → **Tags** tab shows
both keys. (An empty RG shows "No resources" — that's expected at this stage.)

## Key concepts / gotchas

- **Landing zones start with separation of concerns**: network, data and security
  get their own resource groups, so RBAC, locks and costs can be scoped per concern.
- **`locals` are the single source of truth** for names and tags — a naming
  convention in one `locals` block beats repeating strings in each resource.
- **Tags are metadata, not security**: they don't restrict anything, but they drive
  cost breakdowns, policy checks (`inheritTag` policies) and inventory queries.
- All three RGs are independent resources: `terraform destroy` removes all three,
  but each could later live in its own state file / pipeline stage in a real landing zone.
