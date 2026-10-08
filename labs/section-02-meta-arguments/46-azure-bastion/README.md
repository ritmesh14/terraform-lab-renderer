# Lab 46 — Azure Bastion

Bastion gives you RDP/SSH over TLS (port 443) **without** exposing a public IP on the VM.
It needs a dedicated subnet named `AzureBastionSubnet` with a /26 or larger prefix.

This lab deploys a VM with **no public IP** plus a Bastion host, then you connect from the
portal: *Connect → Bastion → username/password*.

> Bastion here uses the **Basic** SKU (the provider default — the config sets no
  `sku`), which still needs ~10 minutes to deploy. Be patient.

## What it creates

| Terraform resource                   | Azure name                  | Notes                                          |
| ------------------------------------ | --------------------------- | ---------------------------------------------- |
| `azurerm_resource_group.this`        | Resource group `rg-bastion` | 1                                              |
| `azurerm_virtual_network.this`       | VNet `vnet-bastion`         | 1, `10.252.0.0/16`                             |
| `azurerm_subnet.vm`                  | Subnet `snet-vm`            | 1, `10.252.1.0/24`, the workload VM            |
| `azurerm_subnet.bastion`             | Subnet `AzureBastionSubnet` | 1, `10.252.2.0/26` — **exact name required**   |
| `azurerm_public_ip.bastion`          | Public IP `pip-bastion`     | 1, for the Bastion only (the VM has none)      |
| `azurerm_bastion_host.this`          | Bastion `bas-secure-access` | 1, in `AzureBastionSubnet`                     |
| `azurerm_network_interface.vm`       | NIC `nic-bastion-vm`        | 1, private IP only                             |
| `azurerm_windows_virtual_machine.vm` | VM `vm-bastion`             | 1, Windows Server 2022, password auth          |

## Commands

```bash
cd 46-azure-bastion
terraform init
terraform plan
terraform apply -var=admin_password="<a strong password>"
terraform output bastion_dns
terraform destroy
```

## What to see in the Azure portal

- Resource group `rg-bastion`: the Bastion host `bas-secure-access`, its public IP, and
  VM `vm-bastion` with **no public IP**.
- VNet `vnet-bastion` → **Subnets**: `snet-vm` and the reserved `AzureBastionSubnet`
  (`/26`).
- Open VM `vm-bastion` → **Connect → Bastion** → sign in with `azureadmin` and the
  password you passed → a browser RDP session opens over 443.

## Key concepts / gotchas

- The subnet name `AzureBastionSubnet` is not a naming suggestion — Bastion refuses to
  deploy into anything else, and the subnet must be `/26` or larger.
- The point of Bastion: the VM keeps a **private-only** NIC; the only internet-exposed
  endpoint is the Bastion's own public IP (TCP 443).
- Windows VMs use `admin_password` (not SSH keys). `sensitive = true` redacts the CLI
  output, but the password is still stored in **state in plain text**.
- Bastion deployment takes ~10 minutes; plan/apply will appear to hang on that resource.
- The `os_disk` / `source_image_reference` nested blocks work exactly like the Linux VM
  in earlier labs — only the image publisher/offer/sku and auth method differ.
