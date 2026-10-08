# Lab 52 — Deploying another web app (assignment)

Self-check: deploy a **second** web app reusing the service plan from lab 51 (data
source), parameterised by a variable. One plan, many apps. Run this lab only after
lab 51's plan exists (`asp-webapp` in `rg-webapp`).

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `data "azurerm_service_plan"` | looks up `asp-webapp` in `rg-webapp` | reads the lab-01 plan, doesn't manage it |
| `azurerm_linux_web_app` | `app-second-<6 random chars>` | new Node app on the **same** plan |
| output | `default_hostname` | the second app's URL |

Nothing else is created — no new resource group or plan.

## Commands

Prerequisite: `az login`, and lab 51 applied (the plan must exist).

```bash
cd 52-another-web-app
terraform init
terraform plan
terraform apply
terraform output default_hostname
terraform destroy    # removes only the second app
```

## What to see in the Azure portal

Resource group **rg-webapp** (the existing one — the lab creates nothing new there
but the app):

- **App Service plan** `asp-webapp` → **Apps** tab now lists **two** apps
  (`app-webapp-...` and `app-second-...`).
- **App Service** `app-second-...` → **Browse**: same default Node page, own URL
  `https://app-second-<suffix>.azurewebsites.net`.

## Key concepts / gotchas

- **`resource` vs `data`** — a `data` block *reads* something that already exists;
  it creates nothing and removing it from the config destroys nothing.
- **One plan, many apps** — apps on the same plan share its compute (and its bill);
  a very busy app can starve others on the same plan.
- **Variables with defaults** — `existing_plan_name` / `existing_rg_name` default to
  lab 51's names; override with `-var "existing_plan_name=..."` if you renamed them.
- **Variables live in `main.tf` here** — `variables.tf` is a placeholder because the
  same variable was once declared in both files, which Terraform rejects (duplicate
  declaration).
- Destroying this lab leaves lab 51's plan and app intact — Terraform only manages
  what this config declares.
