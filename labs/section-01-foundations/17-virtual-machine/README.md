# 17 — Azure Virtual Machine

Bring it all together: VNet + subnet + public IP + NIC + NSG + VM. This is the canonical
"first VM" stack. We use a small Windows Server 2022 image on `Standard_B1s`.

> NB: `admin_password` is marked `sensitive`. Provide it via `terraform.tfvars` (gitignored)
> or a `-var` flag — never commit it.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-vm-foundation` | Container for the stack |
| `azurerm_virtual_network.this` | `vnet-vm` | `10.120.0.0/16` |
| `azurerm_subnet.web` | `snet-web` | `10.120.1.0/24` |
| `azurerm_network_security_group.web` | `nsg-vm` | Allow-RDP (prio 200), any source |
| `azurerm_public_ip.web` | `pip-vm-01` | Static, Standard SKU |
| `azurerm_network_interface.web` | `nic-vm-01` | Subnet + public IP via `ip_configuration` |
| `azurerm_windows_virtual_machine.web` | `vm-web-01` | Win Server 2022, `Standard_B1s` |

## Commands

Prerequisite: `az login` (or the `ARM_*` variables from lab 01).

```bash
cd section-01-foundations/17-virtual-machine
cp terraform.tfvars.example terraform.tfvars   # then edit the password
terraform init
terraform plan
terraform apply
terraform output public_ip
terraform destroy
```

Or pass the password without a tfvars file:

```bash
terraform apply -var "admin_password=ChangeMe12345!"
```

## What to see in the Azure portal

**Resource groups** → `rg-vm-foundation`: you'll see all seven resources listed
together. Open `vm-web-01` → **Overview**:
- **State**: Running; **Size**: `Standard_B1s`.
- **Public IP address**: matches `terraform output public_ip`; **Private IP address**: a
  `10.120.1.x` address.
- **Connect → RDP** and log in with `azureadmin` / the password you set (the NSG rule
  `Allow-RDP` on `nsg-vm` permits port 3389).

## Key concepts / gotchas

- The VM is the **end of a dependency chain** Terraform orders automatically: RG →
  VNet → subnet → public IP/NSG → NIC → VM. Only the NIC reference
  (`network_interface_ids`) is needed on the VM for Terraform to sequence it.
- `admin_password` is a `sensitive` variable: masked in logs, but still stored in the
  state file — treat `terraform.tfstate` as a secret too, and never commit tfvars.
- `source_image_reference` pins the marketplace image by its four-part address
  (publisher/offer/sku/version); `version = "latest"` floats within that SKU.
- `os_disk.storage_account_type = "StandardSSD_LRS"` chooses the OS disk type (vs
  `Premium_LRS` for SSD-backed VMs).
- `Standard_B1s` is a burstable 1 vCPU / 1 GB size — cheap, but the first boot of
  Windows can take a few minutes.