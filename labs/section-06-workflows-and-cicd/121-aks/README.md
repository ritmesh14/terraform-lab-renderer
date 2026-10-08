# Lab 121 — Azure Kubernetes Service via Terraform

Provision a small AKS cluster with a system node pool of 1 node. Azure runs the
Kubernetes control plane for you; this code declares the node pool, its VM size,
the cluster identity and networking. AKS is what you graduate to from ACI (lab 120)
when a container needs scheduling, scaling and self-healing rather than a single box.

> AKS clusters take ~5-10 minutes to create. Use a Standard_B2s node for the pool.

## What it creates / does

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-aks` | Holds the cluster control-plane resources |
| `azurerm_kubernetes_cluster.this` | AKS cluster `aks-cluster` | Kubernetes 1.27, Azure CNI, SystemAssigned identity |
| ↳ `default_node_pool` | Node pool `systempool` | 1 × Standard_B2s, 30 GB OS disk, critical addons only |
| ↳ `identity` block | Managed identity | AKS manages its own resources with no SP secrets |
| ↳ `linux_profile` | Admin account | SSH key from `var.ssh_public_key` (sensitive) |
| ↳ `network_profile` | Azure CNI networking | `service_cidr 10.43.0.0/16`, DNS service IP inside it |
| `output.cluster_name` / `cluster_id` | — | For `az aks get-credentials` / other stacks |

Before running, copy the example tfvars and paste your public SSH key:

```bash
cp terraform.tfvars.example terraform.tfvars   # then edit in your key
```

## Commands

```bash
# Prerequisite: az login
cd 121-aks
terraform init
terraform plan
terraform apply          # takes ~5-10 minutes
az aks get-credentials -g rg-aks -n aks-cluster   # merges kubeconfig locally
kubectl get nodes        # should list the single B2s system node
terraform destroy
```

## What to see

- In the portal: Resource groups → `rg-aks` → `aks-cluster`; plus a second,
  auto-created `MC_rg-aks_aks-cluster_<region>` group holding the node VMs,
  NICs and disks.
- `kubectl get nodes` → one `Ready` node named like `aks-systempool-1`.
- The kubeconfig context Terraform had nothing to do with —
  `get-credentials` is Azure CLI, not Terraform; Terraform only built the cluster.

## Key concepts / gotchas

- **Control plane vs node pool.** `identity`, `dns_prefix` and the API endpoint are
  Azure-managed; your code (and bill) mostly concerns the node pool — 1 × B2s here.
- **`SystemAssigned` identity** removes the classic pain of managing a service
  principal's client secret for the cluster.
- **The tfvars step matters.** `ssh_public_key` has no default and is sensitive —
  without `terraform.tfvars` the apply prompts or fails; `sensitive = true` stops
  the key from being printed in plan/apply output (it still lives in state).
- **Pods can't run here (mostly).** `only_critical_addons_enabled = true` makes
  this a *system* pool; user workloads need an additional node pool or that flag
  removed — a gotcha when `kubectl run` stays Pending.
- **Slow + costly to churn.** AKS changes are slow (minutes) and some fields force
  replacement; keep plan-and-review (labs 118) strict here, and destroy when done.
