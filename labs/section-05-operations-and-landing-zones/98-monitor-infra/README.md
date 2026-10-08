# Lab 98 — Azure Monitor — building our infrastructure

Stand up a small VM to monitor. Later labs attach alerts. This lab is just the
infrastructure under observation.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-monitor` | Container for everything else (eastus) |
| `azurerm_virtual_network.this` | `vnet-monitor` | 10.34.0.0/16 |
| `azurerm_subnet.web` | `snet-web` | 10.34.1.0/24 |
| `azurerm_network_interface.vm` | `nic-monitor` | Dynamic private IP |
| `azurerm_linux_virtual_machine.vm` | `vm-monitor` | Ubuntu 22.04, `Standard_B1s`, SSH-key login |
| output `vm_id` | — | Full resource ID, reused by lab 99's metric alert |

## Commands

Prerequisite: `az login` (Terraform uses your Azure CLI credentials).

```bash
cp terraform.tfvars.example terraform.tfvars   # then paste your SSH public key inside
cd 98-monitor-infra
terraform init
terraform plan
terraform apply
terraform output vm_id
terraform destroy
```

## What to see in the Azure portal

Open resource group **rg-monitor**. You should see `vm-monitor` running
(Standard_B1s), plus its `nic-monitor`, `vnet-monitor`/`snet-web`, and a disk.
Click the VM → **Metrics**: the `Percentage CPU` chart is what lab 99 will alert on.

## Key concepts / gotchas

- This lab is deliberately "boring" infrastructure: monitoring needs something real to watch.
- The VM uses an SSH key, not a password — that key comes from `terraform.tfvars`
  and is marked `sensitive`, so it never shows in plan/apply output.
- The `vm_id` output is the bridge to lab 99: a metric alert must name the
  resource (by ID) whose metric it watches.
- Destroying the resource group removes the VM; lab 99's alert lives in a
  *different* resource group, so it can outlive this lab.
