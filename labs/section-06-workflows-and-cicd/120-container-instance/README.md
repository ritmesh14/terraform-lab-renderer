# Lab 120 — Azure Container Instance via Terraform

ACI is the fastest way to run a container in Azure — no orchestration, no cluster,
just a container group billed per second. This lab runs a public nginx container,
reachable on port 80, in a single resource group. Terraform's job: declare the
container, its image, its resources (CPU/memory) and its ports; Azure does the rest.

## What it creates / does

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-aci` | Container for the stack |
| `azurerm_container_group.this` | Container instance `aci-nginx` | Public IP, Linux, `restart_policy = "Always"` |
| ↳ nested `container` block | Container `nginx` | Image `nginx:1.25-alpine`, 0.5 CPU / 0.5 GB, port 80 TCP |
| `output.public_ip` | — | The address you browse to |

## Commands

```bash
# Prerequisite: az login
cd 120-container-instance
terraform init
terraform plan
terraform apply
terraform output public_ip      # open http://<that-ip> in a browser
terraform destroy               # ACI is billed per second — destroy when done
```

## What to see

- In the portal: Resource groups → `rg-aci` → the container instance `aci-nginx`
  → Overview shows status "Running" and the same IP as the output.
- The nginx welcome page at `http://<public_ip>` (give it a few seconds to pull
  the image the first time).
- In a plan after changing `image`: the container group shows `-/+` (destroy and
  recreate) — container images are immutable, so a new image means a new instance.

## Key concepts / gotchas

- **Container group = Azure's "pod".** One host, one IP, one or more containers
  sharing it (`container` blocks repeat for multi-container groups).
- **No orchestrator, no minimum bill.** ACI is for simple tasks, jobs and demos —
  a pipeline step, a cron-like script. For always-on production services you want
  AKS (lab 121) or Container Apps.
- **The IP is not static** across a recreate. A `-/+` replacement gets a new
  `public_ip` — anything pointing at the old address (DNS, a test) breaks.
- **`restart_policy = "Always"`** keeps the container running like a service;
  other values (`OnFailure`, `Never`) turn ACI into a run-once job.
- **Destroy promptly.** The instance keeps billing while it runs, even if you
  close the terminal — another reason to keep this in Terraform: `terraform
  destroy` is one command, not a portal hunt.
