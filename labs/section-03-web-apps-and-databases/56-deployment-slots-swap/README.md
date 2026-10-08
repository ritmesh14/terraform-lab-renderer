# Lab 56 — Deployment slots — swap

Swapping is a runtime action (Azure CLI), not a Terraform resource. Terraform can't
perform it because a swap changes no desired state — both slots and the app still
exist before and after; only *which code runs where* flips at runtime. Apply lab 55
first, then run:

```bash
az webapp deployment slot swap \
  --name <app-name> --resource-group rg-slots --slot staging --target-slot production
```

The code that was warming up in `staging` is now live in production (and vice versa).
Roll back by swapping again — the previous build is still sitting in `staging`.

## What to see in the Azure portal

Resource group **rg-slots** → App Service `app-slots-...`:

- Before the swap: `staging` serves the new build, `production` the old one.
- After: `https://app-slots-<suffix>.azurewebsites.net` (production) serves what
  staging served a moment earlier, with no redeploy and typically no restart of
  already-warmed instances.

## Key concepts / gotchas

- **Zero-downtime deploys** — swap promotes the warm slot to production instead of
  restarting the production app in place.
- **Swap direction matters** — settings marked "slot sticky" (connection strings,
  app settings flagged as *slot setting*) stay with the slot, not the app, so
  staging keeps pointing at the test database after a swap.
- **Rollback is a second swap** — the old build never left the staging slot.
- This lab has **no Terraform resources of its own** — it's pure Azure CLI against
  what lab 55 created; `terraform apply` in lab 55's folder is unchanged.
