# Lab 35 — Multiple virtual machines

Deploy two Linux VMs with `count`, each with its own NIC. Shows how `count.index`
threads through dependent resources (NICs match VMs by index).

## What it creates

| Terraform resource                     | Azure name                    | Notes                                        |
| -------------------------------------- | ----------------------------- | -------------------------------------------- |
| `azurerm_resource_group.this`          | Resource group `rg-multi-vms` | 1                                            |
| `azurerm_virtual_network.this`         | VNet `vnet-multi-vms`         | 1, address space `10.190.0.0/16`             |
| `azurerm_subnet.web`                   | Subnet `snet-web`             | 1, `10.190.1.0/24`                           |
| `azurerm_network_interface.web`        | NICs `nic-vm-0`, `nic-vm-1`   | **x `vm_count` via `count`** (default 2)     |
| `azurerm_linux_virtual_machine.web`    | VMs `vm-web-0`, `vm-web-1`    | **x `vm_count` via `count`**, Ubuntu 22.04, B1s |

## Commands

```bash
cd 35-multiple-vms
terraform init
terraform plan
terraform apply -var=admin_ssh_key="ssh-rsa AAAA... your@email"
terraform destroy
```

`admin_ssh_key` has no default and is `sensitive` — pass it with `-var` or a
`terraform.tfvars`. `vm_count` (default 2) and `admin_username` (default
`azureadmin`) can be overridden the same way.

## What to see in the Azure portal

- Resource group `rg-multi-vms`: two NICs and two VMs named `...-0` and `...-1`.
- Click `vm-web-0` → **Networking**: the NIC `nic-vm-0` is attached and sits in
  `snet-web` with a dynamic private IP in `10.190.1.0/24`.
- These VMs have **private IPs only** — the config creates no public IP and no
  Bastion, so you cannot `ssh` to them straight from the internet. To connect, add
  a public IP/Bastion yourself or jump from another VM in `snet-web`; the key
  (`azureadmin`, no password) is what the VMs accept.

## Key concepts / gotchas

- Both NICs and VMs share the same `count = var.vm_count`, so instance `i` of the VM
  uses instance `i` of the NIC: `azurerm_network_interface.web[count.index].id`.
- This index-pairing is the classic `count` idiom — and its weakness: changing
  `vm_count` renumbers the list, which can recreate VMs. `for_each` (lab 48) avoids that.
- `sensitive = true` only hides the value in CLI output; the SSH key is still stored
  in **state in plain text**.
- Nested blocks of a VM: `admin_ssh_key` (public-key login), `os_disk`
  (`StandardSSD_LRS`), `source_image_reference` (publisher/offer/sku pin the image).
- `Standard_B1s` is a cheap burstable size — fine for a lab, destroy when done.
