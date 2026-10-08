# Lab 70 — App Service source control (advanced deploy)

Wire a web app to a Git repository so Azure builds and deploys on every push.
In azurerm 3.x this is the `azurerm_app_service_source_control` resource (it works
for Linux web apps too) — give it the app id, a repo URL and branch.

> Azure needs credentials to read a private repo (a PAT). This lab points at a public
> sample repo so no token is needed; for your own repo configure the token outside this
> lab or embed it in the repo URL, and change `repo_url`/`branch` to match.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-appsourcecontrol` | folder for the lab |
| `azurerm_service_plan` | `asp-appsourcecontrol` | Linux `B1` |
| `azurerm_linux_web_app` | `app-sourcecontrol-<6 random chars>` | Node 18-lts |
| `azurerm_app_service_source_control` | (attached to the app) | repo `Azure-Samples/nodejs-docs-hello-world`, branch `main`, `use_manual_integration = false` |
| output | `hostname` | the app URL |

`repo_url` and `branch` are variables with defaults — override to deploy your repo.

## Commands

Prerequisite: `az login`.

```bash
cd 70-app-service-source-control
terraform init
terraform plan
terraform apply
terraform output hostname
terraform destroy
```

## What to see in the Azure portal

Resource group **rg-appsourcecontrol**:

- **App Service** `app-sourcecontrol-...` → **Deployment** → **Deployment Center**:
  shows the GitHub source repo and branch, and the build provider.
- **Deployment Center → Logs** (or *Deployments*): the first deployment runs
  automatically after apply; browse the app URL to see the deployed sample page
  rather than a default placeholder.

## Key concepts / gotchas

- **`use_manual_integration = false`** means continuous CI — every push to `main`
  triggers a build and deploy; `true` would deploy only on manual trigger.
- **No credential block for public repos** — the provider accepts a placeholder
  token for public GitHub repos; private repos need a PAT passed via the resource's
  `basic_auth`/token settings (kept out of this lab).
- **Terraform wires the plumbing once** — pushes afterwards are pure Git; Terraform
  doesn't track deployments, only the binding.
- The resource is `azurerm_app_service_source_control` even for Linux web apps —
  the "app service" name is the 3.x API name, not a Windows-only resource.
- Changing `repo_url`/`branch` in tfvars and re-applying updates the binding in
  place and triggers a new sync.
