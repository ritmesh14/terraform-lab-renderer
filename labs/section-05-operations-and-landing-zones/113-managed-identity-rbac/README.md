# Lab 113 — Managed identity + least-privilege RBAC (advanced)

A VM with a **system-assigned managed identity** can authenticate to Azure without any
stored secret. This lab gives a Linux VM an identity, then grants it **only** the
`Storage Blob Data Reader` role on one storage account — least privilege in action. From
inside the VM you can read blobs using Azure RBAC (no SAS, no key).

Addressing: VNet `172.27.0.0/20`; subnet `172.27.0.0/26`.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `random_string.suffix` | — | 6 chars for the storage name |
| `azurerm_resource_group.this` | `rg-vm-mi` | eastus |
| `azurerm_storage_account.this` | `stvmi<suffix>` | Standard LRS |
| `azurerm_storage_container.data` | `data` | private container |
| `azurerm_virtual_network.this` / `azurerm_subnet.web` | `vnet-vm-mi` / `snet-web` | 172.27.0.0/20, /26 |
| `azurerm_network_interface.vm` | `nic-vm-mi` | dynamic private IP |
| `azurerm_linux_virtual_machine.vm` | `vm-mi` | Ubuntu 22.04, B1s, **SystemAssigned identity** |
| `azurerm_role_assignment.vm_blob_reader` | Storage Blob Data Reader | VM identity → this storage account only |
| outputs `vm_principal_id` / `storage_name` | — | Identity + account name |

## Commands

Prerequisite: `az login`.

```bash
cp terraform.tfvars.example terraform.tfvars   # paste your SSH public key
cd 113-managed-identity-rbac
terraform init
terraform plan
terraform apply
terraform output vm_principal_id
terraform output storage_name
terraform destroy
```

## What to see in the Azure portal

- Resource group **rg-vm-mi**: `vm-mi`, `stvmi<suffix>`, `vnet-vm-mi`.
- VM `vm-mi` → **Security / Identity**: "System assigned" = **On**, with a
  **Object (principal) ID** matching the `vm_principal_id` output.
- Storage account `stvmi<suffix>` → **Access control (IAM) → Role assignments**:
  **Storage Blob Data Reader** assigned to `vm-mi` (not to you).
- From inside the VM (`ssh azureadmin@<private-ip>` from a connected machine), test
  least privilege:
  `az login --identity` then
  `az storage blob list --account-name stvmiXXXX --container data --auth-mode login`
  — works as **read-only**: a `blob put` is refused.

## Key concepts / gotchas

- **System-assigned managed identity** = an Azure AD identity created *by* the
  resource, tied to its lifecycle: destroy the VM, the identity goes too. No password
  or key is ever stored or rotated.
- **The identity is not the VM**: it's a separate service principal. Terraform reads
  its `principal_id` from `identity[0]` so the RBAC grant is created automatically.
- **Least privilege = right role, right scope**: *data-plane* role
  (Storage Blob Data Reader — blob reads only) at *one account's* scope, not
  Contributor at the subscription.
- **Account keys and SAS are not needed here** — RBAC on the data plane means the
  account's storage keys never have to leave Azure at all.
- RBAC assignments can take a couple of minutes to take effect inside the VM, so
  `az login --identity` may fail right after apply — wait and retry.
