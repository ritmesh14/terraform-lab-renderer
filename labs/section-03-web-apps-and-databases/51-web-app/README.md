# Lab 51 — Azure Web App

A Linux App Service running a Node container on the Basic tier. App Service is the
managed PaaS for web apps — no VM, no OS patching, easy scaling. You'll see the two
resources every later lab reuses: a **service plan** (the compute) and a **web app**
(the code that runs on it).

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-webapp` | the folder everything lives in |
| `azurerm_service_plan` | `asp-webapp` | `os_type = "Linux"`, SKU `B1` (Basic) |
| `azurerm_linux_web_app` | `app-webapp-<6 random chars>` | Node 18-lts; `<suffix>` comes from `random_string` (stateful — stable across applies) |
| output | `default_hostname` | the live site URL, e.g. `https://app-webapp-ab12cd.azurewebsites.net` |

## Commands

Prerequisite: `az login` (one-time per session).

```bash
cd 51-web-app
terraform init
terraform plan
terraform apply
terraform output default_hostname   # the site URL
terraform destroy
```

## What to see in the Azure portal

Resource group **rg-webapp**:

- **App Service plan** `asp-webapp` — open it: SKU/size shows `B1`, OS `Linux`.
- **App Service** `app-webapp-...` — open it and click **Browse** (or paste
  `https://app-webapp-<suffix>.azurewebsites.net` into a browser): the default
  Node "hello world" page. The name must be globally unique, which is why the
  random suffix exists.

## Key concepts / gotchas

- **Plan first, app second** — the web app references the plan via
  `service_plan_id`; Terraform creates them in that order automatically.
- **`random_string` is stateful** — it's saved in Terraform state, so re-applying
  doesn't generate a new name (an unstateful trick like `md5(timestamp())` would
  destroy and recreate the app every run).
- **Site names are global** — web app DNS is `<app>.azurewebsites.net` across all
  of Azure, hence the suffix.
- **B1 is not free** — destroy when done. The plan tier controls scaling and
  features (slots need Basic or higher, as lab 55 shows).
