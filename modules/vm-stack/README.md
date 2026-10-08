# vm-stack module

A reusable, opinionated stack: resource group → virtual network → public IP → network
interface → network security group → Linux virtual machine.

This module is built up across labs 77–82 of section 4 and reused in later sections.

## Inputs

| Name | Type | Description |
|---|---|---|
| name_prefix | string | lowercase prefix (3-10 alnum) |
| location | string | Azure region |
| vnet_address_space | list(string) | VNet CIDR |
| subnet_prefix | string | web subnet CIDR |
| admin_username | string | VM admin user |
| admin_ssh_key | string | public SSH key |
| vm_size | string | VM SKU (default Standard_B1s) |
| tags | map(string) | tags applied to all resources |

## Outputs

| Name | Description |
|---|---|
| vm_id | VM resource id |
| vm_name | VM name |
| public_ip | assigned public IP |
| nic_id | NIC id |
| vnet_id | VNet id |
