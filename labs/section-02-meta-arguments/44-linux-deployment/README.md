# Lab 44 — Linux machine — deployment

Lab 43 restructured the files; this lab **deploys** that structure end to end and adds a
public IP plus an NSG so the VM is reachable. Run it and confirm you can SSH in:

```bash
ssh azureadmin@<public_ip>
```

## What it creates

| Terraform resource                     | Azure name                    | Notes                                  |
| -------------------------------------- | ----------------------------- | -------------------------------------- |
| `azurerm_resource_group.this`          | Resource group `rg-linux-deploy` | 1                                   |
| `azurerm_virtual_network.this`         | VNet `vnet-deploy`            | 1, `10.250.0.0/16`                     |
| `azurerm_subnet.web`                   | Subnet `snet-web`             | 1, `10.250.1.0/24`                     |
| `azurerm_network_security_group.web`   | NSG `nsg-deploy`              | 1, Allow TCP 22 (**not associated**)   |
| `azurerm_public_ip.web`                | Public IP `pip-deploy`        | 1, Static / Standard                   |
| `azurerm_network_interface.web`        | NIC `nic-deploy`              | 1, binds subnet + public IP            |
| `azurerm_linux_virtual_machine.web`    | VM `vm-deploy`                | 1, Ubuntu 22.04, SSH key from file     |

## Commands

```bash
cd 44-linux-deployment
terraform init
terraform plan
terraform apply
terraform output public_ip
ssh azureadmin@$(terraform output -raw public_ip)
terraform destroy
```

## What to see in the Azure portal

- Resource group `rg-linux-deploy`: VM `vm-deploy` with NIC `nic-deploy` and static
  public IP `pip-deploy`.
- VM → **Overview** → copy the public IP; `terraform output public_ip` shows the same
  value. With your `id_rsa.pub` (or the placeholder key) you can SSH in as
  `azureadmin` — if the connection is refused or times out, see the NSG-association
  gotcha below (the Allow-SSH rule is not enforced in this lab).
- NSG `nsg-deploy` → **Inbound security rules** shows `Allow-SSH` (TCP 22, priority
  200) — and note the **Subnets** tab has no association in this lab.

## Key concepts / gotchas

- The public IP is wired in the NIC's `ip_configuration`
  (`public_ip_address_id`) — VM → NIC → IP is the Azure wiring order.
- `allocation_method = "Static"` keeps the same address across VM deallocations.
- Suspected gap (left as-is on purpose): the NSG is never attached to the subnet (no
  `azurerm_subnet_network_security_group_association`), so the SSH rule is not
  enforced; inbound access is governed by Azure's default rules instead.
- `source_address_prefix = "*"` means the whole internet — in production pin it to
  your IP or use Azure Bastion (lab 46).
- The SSH key comes from `local.ssh_pubkey` (file read with fallback), exactly like
  lab 42/18.
