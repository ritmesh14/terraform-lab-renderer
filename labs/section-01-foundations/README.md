# Section 1 — Foundations

This section builds the core vocabulary of Terraform on Azure. By the end you will have
created a storage account, a virtual network with subnets, a network interface, a public
IP, a security group, and a virtual machine — all parameterised with variables, locals,
outputs and tfvars.

## How to use these labs

Prerequisites:

- **Terraform >= 1.5** (`terraform -version` to check; lab 22 and 23 need 1.5+)
- **Azure CLI** (`az`) installed
- An Azure subscription you are allowed to create resources in

Typical command flow for every lab:

```bash
az login                              # sign in once per machine/session
cd section-01-foundations/<lab-name>
terraform init                        # download providers (once per lab)
terraform plan                        # preview what will be created
terraform apply                       # create it
terraform output                      # read printed values
terraform destroy                     # tear it down when done
```

Notes:

- Labs 01, 22 and a few others deviate slightly — each lab's README lists its exact
  commands and any extra prerequisites (e.g. an admin password or SSH key for VM labs).
- After `az login`, Terraform authenticates with your user account. For pipeline-style
  (unattended) auth, set up the service principal in lab 01 and export the four
  `ARM_*` environment variables instead.
- Each lab folder is independent: run `terraform init` inside each one and destroy
  before moving on to avoid stray costs.

## Labs

1. [Authentication with an App Registration](01-authentication-app-object/) — service principal
2. [Azure Storage Account](02-storage-account/) — first resource
3. [Upload a Blob](03-upload-blob/) — `azurerm_storage_blob`
4. [References to named values](04-named-value-references/) — `local`, `var`, `azurerm_x.y`
5. [`depends_on`](05-depends-on/) — explicit ordering
6. [Virtual Network](06-virtual-network/)
7. [Local values](07-local-values/)
8. [Split configuration files](08-split-config-files/)
9. [Types — List](09-types-list/)
10. [Types — Map](10-types-map/)
11. [Maps for subnets](11-maps-for-subnets/)
12. [Subnet as a separate resource](12-subnet-resource/)
13. [Network interface](13-network-interface/)
14. [Output values](14-output-values/)
15. [Public IP](15-public-ip/)
16. [Network Security Group](16-network-security-group/)
17. [Virtual Machine](17-virtual-machine/)
18. [Input variables](18-input-variables/)
19. [Variable definition file](19-variable-definition-file/)
20. [Secret values](20-secret-values/)
21. [Data disk](21-data-disk/)

## Conventions used in this section

- A shared `terraform.tf` pins Terraform and the `azurerm` provider.
- `locals.tf` holds derived names and tags.
- Resources live in `main.tf` (small labs) or split files (larger labs).

## Advanced labs

22. [Importing existing resources (`terraform import`)](22-terraform-import/)
23. [`moved` block — refactor without recreate](23-moved-block/)
24. [`templatefile()` — render scripts](24-templatefile/)
25. [`cidrsubnet` / `cidrhost` & `for`](25-cidrsubnet-for/)
