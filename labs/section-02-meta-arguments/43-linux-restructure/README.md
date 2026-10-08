# Lab 43 — Linux machine — restructure

The same VM as lab 42, but split into `terraform.tf`, `locals.tf`, `variables.tf`,
`network.tf`, `vm.tf`, `outputs.tf`. This is the structure every serious project uses.

## What it creates

| Terraform resource                  | Azure name                      | Notes                              |
| ----------------------------------- | ------------------------------- | ---------------------------------- |
| `azurerm_resource_group.this`       | Resource group `rg-linux-structure` | 1                              |
| `azurerm_virtual_network.this`      | VNet `vnet-structure`           | 1, `10.240.0.0/16`                 |
| `azurerm_subnet.web`                | Subnet `snet-web`               | 1, `10.240.1.0/24`                 |
| `azurerm_network_interface.web`     | NIC `nic-structure`             | 1                                  |
| `azurerm_linux_virtual_machine.web` | VM `vm-structured` (from var)   | 1, Ubuntu 22.04                    |

## Commands

```bash
cd 43-linux-restructure
terraform init
terraform plan
terraform apply -var=vm_name="vm-renamed"
terraform output vm_id
terraform destroy
```

## What to see in the Azure portal

- Resource group `rg-linux-structure`: NIC `nic-structure` and the VM named by
  `var.vm_name` (default `vm-structured`), attached to that NIC in `snet-web`.
- `terraform output vm_id` prints the full Azure resource ID of the VM.

## Key concepts / gotchas

- Terraform loads **every `.tf` file in the folder as one configuration** — the split
  into files is purely organizational; there is no import order or scope.
- Conventional layout: `terraform.tf` (version/provider), `variables.tf` (inputs),
  `locals.tf` (derived values), `network.tf` / `vm.tf` (grouped by concern),
  `outputs.tf` (results).
- References (`var.vm_name`, `local.ssh_pubkey`, `azurerm_network_interface.web.id`)
  work across files — resources in `vm.tf` depend on `network.tf` exactly as before.
- One rule still applies: an identifier (`variable "vm_name"`, a resource address)
  may be declared **only once** across the whole folder.
- Keeping the VM in its own file makes it trivial to find and to grow (disks, zones,
  count) without touching the network code.
