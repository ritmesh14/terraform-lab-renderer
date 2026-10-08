# 21 — Adding a data disk

Attach a managed data disk to the VM from lab 17 using
`azurerm_managed_disk` + `azurerm_virtual_machine_data_disk_attachment`. The OS disk holds
the OS; data disks hold your application data and can be detached and re-attached.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-disk-foundation` | Container for the lab |
| `azurerm_virtual_network.this` / `azurerm_subnet.web` / `azurerm_network_interface.web` | `vnet-disk` / `snet-web` / `nic-disk` | Same VM plumbing as lab 20 |
| `azurerm_windows_virtual_machine.web` | `vm-disk-01` | OS disk StandardSSD, Win Server 2022 |
| `azurerm_managed_disk.data` | `disk-data-01` | Empty 32 GB, StandardSSD |
| `azurerm_virtual_machine_data_disk_attachment.data` | — | LUN 0, ReadWrite cache |

## Commands

Prerequisite: `az login` (or the `ARM_*` variables from lab 01) and an admin password:

```bash
cd section-01-foundations/21-data-disk
cp terraform.tfvars.example terraform.tfvars   # edit the password first
terraform init
terraform plan
terraform apply
terraform destroy
```

## What to see in the Azure portal

**Resource groups** → `rg-disk-foundation` → `vm-disk-01` → **Disks**. You should see
two disks: the OS disk (auto-created with the VM, ~127 GiB) and `disk-data-01`
(32 GiB) with LUN 0. Open `disk-data-01` → **Overview**: it reports *Attached to VM:
vm-disk-01* — that's the attachment resource. From inside the VM (Disk Management), the
new disk appears unallocated and needs to be initialized/formatted.

## Key concepts / gotchas

- **OS disk vs data disk**: the OS disk is part of the VM resource (`os_disk {}` block)
  and dies with it; a data disk is a standalone `azurerm_managed_disk` that can be
  detached and re-attached to another VM.
- `create_option = "Empty"` makes a blank disk; `"Copy"` would clone from a snapshot or
  an existing disk.
- The **attachment is its own resource**, not an attribute of the VM — that's why
  detaching doesn't destroy the disk (or the VM).
- `lun = 0` is the disk's slot number the guest OS sees; each additional disk needs a
  unique LUN. Order matters: LUN 0 for the first disk, 1 for the next, etc.
- Caching: `ReadWrite` suits OS/app disks; data disks used only for writes often use
  `None` to protect against host-cache loss.