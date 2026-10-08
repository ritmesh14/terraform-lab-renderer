# Section 4 — Modules and networking

Build a reusable **local module** end to end, then tackle the heavier network appliances:
Load Balancer, Virtual Machine Scale Set, Traffic Manager, VNet peering, Application
Gateway and Azure Firewall.

## How to use these labs

Prerequisites:

- **Terraform >= 1.5** (`terraform -version` to check)
- **Azure CLI** and a subscription you can create resource groups in — run `az login`
  once per session; Terraform picks up that login's subscription.
- An **SSH public key** (`~/.ssh/id_ed25519.pub` or similar) for the VM labs.

Typical command flow, run from inside a lab folder:

```bash
cd labs/section-04-modules-and-networking/<lab-folder>
az login                                  # once, before the first lab of the day
cp terraform.tfvars.example terraform.tfvars   # only in labs that need it (fill in your SSH key or IP inputs)
terraform init      # downloads providers + any modules
terraform plan      # preview
terraform apply     # type yes; load balancers/firewalls/app gateways take minutes
terraform output    # grab IPs / DNS names to test in the portal
terraform destroy   # clean up before moving on
```

Notes:

- Labs 73-78 consume the shared local modules in `labs/modules/` — that is the point:
  the root configs are thin callers. Lab 93 switches to a public registry module.
- Some labs are split (setup + implementation, e.g. 14/15, 16-20): the later lab reads
  the earlier lab's `terraform output` values into its `terraform.tfvars`, so run them
  in order.
- Each lab's README lists exactly what it creates, the portal pages to inspect, and the
  concepts/gotchas — read the lab README before its code.

## Labs

73. [Modules — resource group](73-module-resource-group/)
74. [Modules — virtual network](74-module-vnet/)
75. [Modules — public IP & NIC](75-module-ip-nic/)
76. [Modules — network security groups](76-module-nsg/)
77. [Modules — virtual machines](77-module-vm/)
78. [Modules — copy files to server](78-module-copy-files/)
79. [Azure Load Balancer](79-load-balancer/)
80. [Virtual Machine Scale Set](80-vmss/)
81. [Traffic Manager — web apps](81-traffic-manager/)
82. [Traffic Manager — implementation](82-traffic-manager-impl/)
83. [VNet peering — setup](83-vnet-peering-setup/)
84. [VNet peering — machines](84-vnet-peering-machines/)
85. [VNet peering — implementation](85-vnet-peering-impl/)
86. [Application Gateway — VMs](86-app-gateway-vms/)
87. [Application Gateway — implementation](87-app-gateway-impl/)
88. [Azure Firewall — VMs](88-firewall-vms/)
89. [Azure Firewall — deploy](89-firewall-deploy/)
90. [Azure Firewall — routing](90-firewall-routing/)
91. [Azure Firewall — NAT rule](91-firewall-nat-rule/)
92. [Azure Firewall — application rule](92-firewall-app-rule/)
93. [Using a registry module](93-registry-module/)

## Advanced labs

94. [Internal Load Balancer](94-internal-load-balancer/)
95. [Application Gateway — path-based routing](95-app-gateway-path-routing/)
96. [Application Gateway — SSL via Key Vault](96-app-gateway-ssl/)
97. [Azure Firewall — policy-based](97-firewall-policy/)
