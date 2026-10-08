# 05 — `depends_on`

Terraform normally infers dependency order from references. When two resources have no
direct reference but **must** still be ordered, use `depends_on` to make it explicit.
This lab shows both kinds of dependency in one config: an *implicit* one (the storage
account references the resource group) and an *explicit* one (the container).

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-depends-foundation` | Created first |
| `azurerm_storage_account.this` | `stdep<suffix>` | Implicit dependency via references |
| `azurerm_storage_container.data` | `data` | **Explicit** dependency via `depends_on` |

## How the ordering works

- `azurerm_storage_account.this` references `azurerm_resource_group.this.name` /
  `.location`, so Terraform knows it must come after the RG — no `depends_on` needed.
- `azurerm_storage_container.data` only passes `storage_account_name = local.st_name`,
  a plain string. Terraform cannot see from that string that the account must exist
  first, so the container declares `depends_on = [azurerm_storage_account.this]`.

This lab creates a resource group, then a storage account, then a container. The
container has no attribute reference to the storage account beyond its name (which is a
plain string), so we add `depends_on` to guarantee ordering.

## Commands

Prerequisite: `az login` (or the `ARM_*` variables from lab 01).

```bash
cd section-01-foundations/05-depends-on
terraform init
terraform plan    # notice the order Terraform lists: RG -> storage account -> container
terraform apply
terraform destroy
```

## What to see in the Azure portal

**Resource groups** → `rg-depends-foundation` → the storage account starting with
`stdep` → **Storage browser → Blob containers** → the container named `data`, private.

## Key concepts / gotchas

- **Implicit dependencies** (real references) are always preferred — they carry real
  data and keep the graph honest.
- `depends_on` takes a list of resource *addresses*, e.g.
  `[azurerm_storage_account.this]` — never attribute values.
- A resource with `depends_on` also waits for *everything its target depends on*, so
  the container transitively waits for the resource group too.
- Prefer a real reference over `depends_on` whenever possible — `depends_on` is a code
  smell that says "the graph isn't expressible through data".
- In a plan, the ordering is visible in the creation list: RG, storage account, then
  container.