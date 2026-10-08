# Lab 55 — Deployment slots — create

Slots let you stage a new build and warm it up before swapping it into production.
This lab creates a web app **plus** a `staging` slot. Slots require a Basic or
higher plan — that's why the plan here is `B1`, not Free.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-slots` | folder for the lab |
| `azurerm_service_plan` | `asp-slots` | Linux `B1` — supports slots |
| `azurerm_linux_web_app` | `app-slots-<6 random chars>` | the production app, Node 18-lts |
| `azurerm_linux_web_app_slot` | `staging` (child of the app) | own hostname, shares the plan |
| outputs | `prod_hostname`, `staging_hostname` | both live URLs |

## Commands

Prerequisite: `az login`.

```bash
cd 55-deployment-slots-create
terraform init
terraform plan
terraform apply
terraform output staging_hostname
terraform destroy
```

## What to see in the Azure portal

Resource group **rg-slots**:

- **App Service** `app-slots-...` → **Deployment** → **Deployment slots**: the list
  shows `production` (the app itself) and `staging`.
- The staging slot has its **own URL** —
  `https://app-slots-<suffix>-staging.azurewebsites.net` (the slot name becomes a
  subdomain). Browse both: they're separate running apps.
- Slot-level settings (**Environment variables**, **Configuration**) are separate
  per slot — that's how you can point staging at a test database.

## Key concepts / gotchas

- **A slot is a second copy of the app** on the same plan — same compute, its own
  config, its own hostname. It counts toward the plan's slot allowance (B1: 5).
- **Slots need Basic+** — on the Free tier the resource would be rejected.
- **The slot resource takes `app_service_id`** (no separate location/resource group)
  — it inherits those from the parent app.
- **Swap is a runtime action**, not Terraform — see lab 56 for the `az` CLI command.
- In `site_config`, both app and slot declare the same `node_version`; a slot can
  run a different runtime (that's the point — test the new stack in staging).
