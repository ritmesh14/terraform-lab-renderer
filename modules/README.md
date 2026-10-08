# Reusable modules

A **module** is a folder of Terraform files you can call from elsewhere. Modules are how
you avoid copy-pasting the same resource blocks across every project — write the pattern
once, call it many times with different inputs.

This folder holds **five small, focused local modules** that the labs (especially
section 4) call. They double as a worked example of how to *build* a module: a clean
contract of inputs (`variables.tf`), resources (`main.tf`), and outputs (`outputs.tf`).

> Modules here are **local** (referenced by a relative path like `source = "../../modules/vnet"`).
> You run `terraform init` once per caller so Terraform copies the module into `.terraform/`.
> The same `module {}` block works with registry or Git sources too — see
> `labs/section-04-modules-and-networking/93-registry-module`.

## What a module looks like

Every module folder has the same shape:

| File | Role |
|---|---|
| `versions.tf` | Pins Terraform + the `azurerm` provider version (so the module is reproducible on its own). |
| `variables.tf` | The module's **inputs** — the contract a caller must satisfy. Each has a `type`, a `default` (optional), and `validation` where it matters. |
| `main.tf` | The **resources** the module creates. They reference `var.*` for inputs. |
| `outputs.tf` | The module's **returned values**. Callers read these as `module.<name>.<output>`. |

A caller does **not** see the resources inside `main.tf` — only the variables and outputs.
That encapsulation is the whole point: change the implementation without changing callers.

## The five modules

| Module | Creates | Used by labs | One-line purpose |
|---|---|---|---|
| [`rg-only`](rg-only/) | 1 resource group | 04-01 | The smallest possible module: name+location in, id+name out. |
| [`vnet`](vnet/) | RG + VNet + N subnets | 04-02, 04-03, 04-04 | A network you configure with parallel subnet name/prefix lists. |
| [`ip-nic`](ip-nic/) | public IP + NIC | 04-03 | A NIC bound to a given `subnet_id` — shows a module consuming another module's id. |
| [`nsg`](nsg/) | NSG + subnet association | 04-04 | An NSG whose Allow rules come from a `list(number)` of ports via a `dynamic` block. |
| [`vm-stack`](vm-stack/) | RG → VNet → subnet → NSG → public IP → NIC → VM | 04-05, 04-06 | A complete, opinionated VM stack in one call. |

## How to call a module

```hcl
module "stack" {
  source = "../../modules/vm-stack"   # relative path to the module folder

  name_prefix        = "modvm"        # ---- inputs (must match variables.tf) ----
  location           = "eastus"
  admin_ssh_key      = var.admin_ssh_key
  vnet_address_space = ["10.14.0.0/16"]
  subnet_prefix      = "10.14.1.0/24"
  tags               = { project = "section-04" }
}

output "public_ip" { value = module.stack.public_ip }   # read an output
```

Then:
```bash
terraform init    # copies/links the module into .terraform/
terraform plan
terraform apply
```

## Inputs & outputs at a glance

### `rg-only`
- **In:** `name`, `location`, `tags` (map, optional)
- **Out:** `id`, `name`

### `vnet`
- **In:** `name`, `location`, `address_space` (list), `subnet_prefixes` (list), `subnet_names` (list), `tags` (optional)
- **Out:** `vnet_id`, `subnet_ids` (list), `subnet_names`

### `ip-nic`
- **In:** `name`, `location`, `resource_group_name`, `subnet_id`, `tags` (optional)
- **Out:** `nic_id`, `public_ip`

### `nsg`
- **In:** `name`, `location`, `resource_group_name`, `allowed_ports` (list(number)), `subnet_id`, `tags` (optional)
- **Out:** `nsg_id`

### `vm-stack`
- **In:** `name_prefix` (validated 3–10 lowercase alnum), `location`, `vnet_address_space`, `subnet_prefix`, `admin_username`, `admin_ssh_key` (sensitive), `vm_size`, `custom_data` (optional), `tags` (optional)
- **Out:** `vm_id`, `vm_name`, `public_ip`, `nic_id`, `vnet_id`

> `admin_ssh_key` is `sensitive` — it never appears in plan/apply output. `custom_data`
> accepts base64-encoded cloud-init (see `labs/.../78-module-copy-files`).

## Module conventions used here

1. **One concern per module** — `vnet` does networking; `nsg` does firewall rules. Don't
   bundle unrelated resources.
2. **Every tunable knob is a variable** with a sensible `default` where optional, so
   callers only set what they care about.
3. **Validate inputs early** — e.g. `name_prefix` uses `can(regex(...))` so a bad name
   fails before any resource is created.
4. **Return useful outputs** so modules chain: `vnet` returns `subnet_ids`, which `ip-nic`
   and `nsg` consume.
5. **Pin the provider** in each module's `versions.tf` so it works standalone too.
6. **Don't hard-code names** — derive them from inputs (e.g. `rg-${var.name_prefix}`).

## Where to go next

- Build the smallest module: `labs/section-04-modules-and-networking/73-module-resource-group`
- See modules chain together: `03-module-ip-nic` (consumes `vnet`'s output)
- Consume a module from the public Terraform Registry: `21-registry-module`
- The concept guide: [`docs/concepts/modules.md`](../docs/concepts/modules.md)
