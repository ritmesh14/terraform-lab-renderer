# 01 — Authentication with an App Registration

This lab shows how to authenticate Terraform to Azure using a **service principal** (an
App Registration / Enterprise Application) instead of an interactive login. This is the
foundation for any CI/CD pipeline. It creates **no Azure resources** — the only goal is to
prove that Terraform can sign in with the credentials you export.

## What it creates

Nothing. The configuration only *reads* Azure information:

| Terraform resource | Azure name | Notes |
|---|---|---|
| `data "azurerm_subscription" "current"` | Your subscription | Read-only; proves the credentials work |
| `output "subscription_id"` / `output "display_name"` | — | Print what Terraform authenticated against |

## Steps

1. Create the service principal ( Contributor role on your subscription):

   ```bash
   az ad sp create-for-rbac --name "tf-learn-sp" --role Contributor \
     --scopes "/subscriptions/<SUBSCRIPTION_ID>"
   ```

   The output contains `appId` (client id), `password` (client secret), `tenant` and
   the subscription id.

2. Export the credentials as environment variables:

   bash (Linux/macOS):

   ```bash
   export ARM_SUBSCRIPTION_ID="<subscription-id>"
   export ARM_CLIENT_ID="<appId>"
   export ARM_CLIENT_SECRET="<password>"
   export ARM_TENANT_ID="<tenant>"
   ```

   PowerShell (Windows):

   ```powershell
   $env:ARM_SUBSCRIPTION_ID="<subscription-id>"
   $env:ARM_CLIENT_ID="<appId>"
   $env:ARM_CLIENT_SECRET="<password>"
   $env:ARM_TENANT_ID="<tenant>"
   ```

   cmd (Windows):

   ```cmd
   set ARM_SUBSCRIPTION_ID=<subscription-id>
   set ARM_CLIENT_ID=<appId>
   set ARM_CLIENT_SECRET=<password>
   set ARM_TENANT_ID=<tenant>
   ```

3. The `azurerm` provider picks these up automatically — no secrets in the code:

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## What to see

Because nothing is created, there is no resource group to visit. Instead, after
`terraform apply` the outputs print your subscription id and display name — if Terraform
could read them, authentication works. You can cross-check the same values with
`az account show`.

## Why bother?

- Reproducible, headless runs in pipelines.
- Least-privilege: scope the SP to a resource group instead of a subscription.
- No interactive `az login` needed on build agents.

## Key concepts / gotchas

- A **service principal** is an identity for *applications* (or pipelines), not people —
  created via `az ad sp create-for-rbac`, which also generates the client secret.
- Terraform reads the four `ARM_*` environment variables automatically; credentials are
  never written into the `.tf` files.
- This lab has no `resource` blocks at all, only a `data` block — a first look at the
  difference between *reading* and *creating* Azure objects.
- If `terraform plan` fails with an auth error, the `ARM_*` variables are missing,
  misspelled, or the secret expired.