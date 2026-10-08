# Script — Lab 46: The Locked Door: Azure Bastion

*Terraform Meta-arguments — Lab 46. Generated from `source/terraform-inventory.json` + `source/source-manifest.json` (ACTIVE_LAB = `section-02-meta-arguments/46-azure-bastion`).*

---

## S001 — TITLE: The Locked Door: Azure Bastion

**The Locked Door: Azure Bastion**

Welcome back. Every VM we've deployed lately had a public IP — a door on the open internet. This is Lab 46, and we take that door away. The VM goes private-only, and access comes through Azure Bastion — a managed jump box that brokers RDP over TLS on 443. Plus the rule Bastion enforces before anything deploys: a subnet literally named AzureBastionSubnet. Let's build it.

---

## S002 — CONCEPT: What you'll learn

- A Windows VM with NO public IP — the internet never sees it
- AzureBastionSubnet: the exact name + a /26 prefix Bastion requires
- Bastion brokers RDP over TLS 443 — Connect → Bastion from the portal

**What you'll learn**

Three things in this lesson. One: the deployment itself — a Windows virtual machine with a private-only NIC; no public IP anywhere on the VM. Two: the naming rule — Bastion refuses to deploy unless its subnet is EXACTLY named AzureBastionSubnet and is at least a slash 26. Three: the access path — you connect from the portal, Bastion brokers the RDP session over TLS on port 443, and the only internet-exposed endpoint is Bastion's own address.

---

## S003 — CONCEPT: Where this lab fits

- Labs 44/45: reachability = a static public IP on the NIC
- This lab: reachability WITHOUT a public IP on the VM
- The rules Bastion enforces are Azure-side, not Terraform-side

**Where this lab fits**

Placement. Labs 44 and 45 made VMs reachable the direct way — a static public IP on the NIC, SSH from the internet. This lab is the other design: nothing on the VM is internet-facing; Bastion is the single controlled door. One thing to keep straight: the AzureBastionSubnet naming and the slash 26 are Azure's rules, checked at deploy time — Terraform happily plans a wrong subnet name; Azure is the one that refuses it.

---

## S004 — CONCEPT: Where to find this lab

**Where to find this lab**

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-02-meta-arguments
          └── 46-azure-bastion

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-02-meta-arguments/46-azure-bastion
```

You'll find this lab in the course GitHub repository under Section 2, Meta-arguments — the lab named 46-azure-bastion. The direct link is in the video description. Main dot T F holds everything; terraform dot T F pins the providers.

---

## S005 — CODE

Terraform dot T F pins the tooling: Terraform 1.5 or newer, and the azurerm provider around version 3.70 — no extra providers this time. The provider block at the bottom bridges to Azure; the empty features block enables the provider's defaults.

---

## S006 — CODE

**Steps:**

1. One input: admin password, a string marked sensitive = true. Windows VMs authenticate with a password, not an SSH key — and sensitive hides the value from plan and apply output. It does NOT hide it from the state file — hold that thought for the pitfalls.
   - active: [7, 8, 9]

One input: admin password, a string marked sensitive = true. Windows VMs authenticate with a password, not an SSH key — and sensitive hides the value from plan and apply output. It does NOT hide it from the state file — hold that thought for the pitfalls.

---

## S007 — CODE

**Steps:**

1. The container: resource group rg dash bastion.
   - active: [12, 13, 14, 15]
2. And the VNet: vnet dash bastion on 10.252 slash 16 — it hosts BOTH subnets this lab needs: the workload subnet and the Bastion subnet.
   - active: [18, 19, 22]

The container: resource group rg dash bastion. And the VNet: vnet dash bastion on 10.252 slash 16 — it hosts BOTH subnets this lab needs: the workload subnet and the Bastion subnet.

---

## S008 — CODE

**Steps:**

1. The workload subnet: snet dash vm on 10.252.1 slash 24. The VM lives here — private IPs only.
   - active: [26, 27, 30]
2. And the special one. Its name is not a suggestion — AzureBastionSubnet, spelled exactly, capital A, capital B, capital S. And the prefix is a slash 26 — Bastion requires /26 or larger. Get either wrong and Terraform plans it fine, but Azure refuses the deployment.
   - active: [34, 35, 38]

The workload subnet: snet dash vm on 10.252.1 slash 24. The VM lives here — private IPs only. And the special one. Its name is not a suggestion — AzureBastionSubnet, spelled exactly, capital A, capital B, capital S. And the prefix is a slash 26 — Bastion requires /26 or larger. Get either wrong and Terraform plans it fine, but Azure refuses the deployment.

---

## S009 — CODE

**Steps:**

1. One public IP in this lab — and it belongs to BASTION, not the VM: pip dash bastion, static allocation on the standard SKU. Clients hit this address on 443; the VM never gets one.
   - active: [43, 44, 47, 48]

One public IP in this lab — and it belongs to BASTION, not the VM: pip dash bastion, static allocation on the standard SKU. Clients hit this address on 443; the VM never gets one.

---

## S010 — CODE

**Steps:**

1. The Bastion host itself: bas dash secure dash access, the managed jump box. Note what's NOT here — no sku argument. The provider default is Basic, and Basic is enough for this lab's portal connection; it still takes about ten minutes to deploy, so plan and apply appear to hang on this one resource. Patience.
   - active: [53, 54, 55, 56]
2. The ip configuration wires the two halves: subnet id points at AzureBastionSubnet, and public ip address id at pip bastion. Those two references are what makes the host deployable.
   - active: [57, 59, 60]

The Bastion host itself: bas dash secure dash access, the managed jump box. Note what's NOT here — no sku argument. The provider default is Basic, and Basic is enough for this lab's portal connection; it still takes about ten minutes to deploy, so plan and apply appear to hang on this one resource. Patience. The ip configuration wires the two halves: subnet id points at AzureBastionSubnet, and public ip address id at pip bastion. Those two references are what makes the host deployable.

---

## S011 — CODE

**Steps:**

1. The VM's NIC: nic dash bastion dash vm, attached to snet vm with a DYNAMIC private IP. Look at what's missing — there is no public ip address id in this ip configuration. That omission IS the security posture: the NIC is private-only, by design.
   - active: [65, 66, 71, 72]

The VM's NIC: nic dash bastion dash vm, attached to snet vm with a DYNAMIC private IP. Look at what's missing — there is no public ip address id in this ip configuration. That omission IS the security posture: the NIC is private-only, by design.

---

## S012 — CODE

**Steps:**

1. The Windows VM: vm dash bastion, NIC from the block above — and admin password equals var dot admin password, the sensitive input. No admin ssh key block at all — Windows authenticates with the password.
   - active: [78, 79, 85]
2. The nested blocks match the Linux anatomy exactly — os disk on standard SSD, and the source image reference pointing at Windows Server 2022 datacenter azure edition. Only the publisher and the auth method changed.
   - active: [86, 90, 93]

The Windows VM: vm dash bastion, NIC from the block above — and admin password equals var dot admin password, the sensitive input. No admin ssh key block at all — Windows authenticates with the password. The nested blocks match the Linux anatomy exactly — os disk on standard SSD, and the source image reference pointing at Windows Server 2022 datacenter azure edition. Only the publisher and the auth method changed.

---

## S013 — CODE

**Steps:**

1. Two outputs: bastion dns — the address you'll open the portal session from — and the VM's name. The VM deliberately has no public ip output. There isn't one.
   - active: [99, 100]

Two outputs: bastion dns — the address you'll open the portal session from — and the VM's name. The VM deliberately has no public ip output. There isn't one.

---

## S014 — DIAGRAM: How the pieces connect

**How the pieces connect**

**Steps:**

1. Here's how the pieces connect.
2. The resource group and VNet — one VNet hosting both the workload subnet and the Bastion subnet.
   - active: ['rg', 'vnet']
3. Two subnets: the VM's snet dash vm, and the reserved AzureBastionSubnet — exact name required, /26 or larger.
   - active: ['snetvm', 'snetbast']
4. The public IP — Bastion's only internet exposure, for the 443 listener. The VM gets none.
   - active: ['pip']
5. The Bastion host: bound to AzureBastionSubnet and that public IP inside its ip configuration.
   - active: ['bastion']
6. The workload side: a private-only NIC and the Windows VM — reachable through Bastion, never from the internet.
   - active: ['nic', 'vm']
7. Everything lands inside your Azure subscription.

Here's how the pieces connect. The resource group and VNet — one VNet hosting both the workload subnet and the Bastion subnet. Two subnets: the VM's snet dash vm, and the reserved AzureBastionSubnet — exact name required, /26 or larger. The public IP — Bastion's only internet exposure, for the 443 listener. The VM gets none. The Bastion host: bound to AzureBastionSubnet and that public IP inside its ip configuration. The workload side: a private-only NIC and the Windows VM — reachable through Bastion, never from the internet. Everything lands inside your Azure subscription.

---

## S015 — TERMINAL

Here's the plan — terraform plan, an illustrative view. Eight to add: resource group, VNet, TWO subnets, the public IP, the Bastion host, the NIC, and the Windows VM. The password shows redacted as a sensitive value — and note which resource does NOT appear: a public IP for the VM. There isn't one.

---

## S016 — TERMINAL

And the outputs — terraform output, an illustrative view. Bastion dns, and the VM's name. To reach the machine you open the VM in the portal, choose Connect → Bastion, sign in as azureadmin with the password variable — and a browser RDP session opens over 443.

---

## S017 — CONCEPT: Common pitfall

- The subnet MUST be named AzureBastionSubnet, /26 or larger — Azure refuses anything else
- sensitive hides the password in CLI output — it's still PLAIN TEXT in the state file
- Bastion takes ~10 minutes to deploy — plan/apply appears to hang on the host

**Common pitfall**

Three pitfalls. One: the subnet name is enforced by Azure, not Terraform — the plan will look perfect with any name, and the apply will fail at deploy time unless it's exactly AzureBastionSubnet, on a /26 or larger. Two: sensitive equals true only redacts the CLI — the password is stored in the state file in plain text; that's one more reason state files never get committed. Three: Bastion is one of the slowest resources in Azure — around ten minutes — so the apply will look stuck on the host; it isn't. Wait it out.

---

## S018 — RECAP

- VM with NO public IP — nic-bastion-vm is private-only by design
- AzureBastionSubnet: exact name + /26 prefix, enforced by Azure at deploy
- pip-bastion (Static/Standard) is the ONLY internet-facing endpoint — TCP 443
- Bastion brokers RDP over TLS: portal → Connect → Bastion → sign in
- Windows VM: admin_password (sensitive) instead of an SSH key

Quick recap — five things. One: the VM has no public IP — its NIC is private-only, and that omission is the design. Two: the Bastion subnet must be exactly AzureBastionSubnet on a /26 or larger — Azure enforces both at deploy time. Three: the only internet-facing endpoint is Bastion's own public IP, on 443. Four: access goes through the portal — Connect, Bastion, sign in — and Bastion brokers RDP over TLS. Five: the Windows VM authenticates with the sensitive password variable, not an SSH key. The door moved off the VM and onto a managed broker.

---

## S019 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

---

## S020 — CONCEPT: Thanks for watching

**Thanks for watching**

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-02-meta-arguments/46-azure-bastion
```

Thanks for watching. If this helped, the full lab — along with every lab in this course — is in the GitHub repository linked in the description. See you in the next one.

---
