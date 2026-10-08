# Script — Lab 45: Provisioners: The Last Resort

*Terraform Meta-arguments — Lab 45. Generated from `source/terraform-inventory.json` + `source/source-manifest.json` (ACTIVE_LAB = `section-02-meta-arguments/45-provisioners`).*

---

## S001 — TITLE: Provisioners: The Last Resort

**Provisioners: The Last Resort**

Welcome back. Lab 40 configured a server with cloud-init — the preferred way. This is Lab 45, and it teaches the mechanism Terraform documentation itself tells you to avoid: provisioners. A remote-exec over SSH that runs at create time. The lab exists so you recognize one in the wild and know exactly why it's the last resort. Let's look.

---

## S002 — CONCEPT: What you'll learn

- Provisioners run at create/destroy time — not idempotent, not in plan
- provisioner "remote-exec" + a connection block over SSH
- TWO key halves: admin_public_key (VM trusts) vs admin_private_key (Terraform signs)

**What you'll learn**

Three things in this lesson. One: what a provisioner IS — a script that runs once, at create or destroy time, outside the plan; it isn't idempotent and a failure taints the resource. Two: the mechanics — a remote-exec provisioner with a connection block, over SSH, using the self reference. Three: the keypair discipline this lab got right after a correction — the public half is what the VM trusts, the private half is what Terraform signs with. Two variables, on purpose.

---

## S003 — CONCEPT: Where this lab fits

- Lab 40: cloud-init + custom_data — the PREFERRED configuration path
- This lab: provisioners, taught LAST on purpose — mechanics only
- Use one only when nothing else can do the job (file copy, bootstrap, cleanup)

**Where this lab fits**

Placement. Lab 40 showed the right way to configure a VM: cloud-init, at first boot, in the VM's own build. Provisioners come LAST in this course on purpose — the README and Terraform's own docs agree they're a last resort. You'll learn the mechanics today so you can recognize and review them — not reach for them first. The legit uses are narrow: copying a local file nothing else can move, bootstrapping a config manager, cleanup on destroy.

---

## S004 — CONCEPT: Where to find this lab

**Where to find this lab**

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-02-meta-arguments
          └── 45-provisioners

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-02-meta-arguments/45-provisioners
```

You'll find this lab in the course GitHub repository under Section 2, Meta-arguments — the lab named 45-provisioners. The direct link is in the video description. Main dot T F holds everything; terraform dot T F pins the providers.

---

## S005 — CODE

Terraform dot T F pins the tooling: Terraform 1.5 or newer, and the azurerm provider around version 3.70 — no extra providers this time. The provider block at the bottom bridges to Azure; the empty features block enables the provider's defaults.

---

## S006 — CODE

**Steps:**

1. Two sensitive variables — and the comments above them explain the split. Admin public key: what the VM TRUSTS, fed to the admin ssh key block. Admin private key: what Terraform SIGNS with when the provisioner SSHes in.
   - active: [10, 11, 12, 13]
2. A public key can never stand in for a private key — they're different halves of the same keypair, and this lab declares them as separate variables on purpose. Both are sensitive; both stay out of the plan output.
   - active: [14, 15, 16, 17]

Two sensitive variables — and the comments above them explain the split. Admin public key: what the VM TRUSTS, fed to the admin ssh key block. Admin private key: what Terraform SIGNS with when the provisioner SSHes in. A public key can never stand in for a private key — they're different halves of the same keypair, and this lab declares them as separate variables on purpose. Both are sensitive; both stay out of the plan output.

---

## S007 — CODE

**Steps:**

1. The network base: VNet on 10.251 slash 16, subnet snet web. Familiar shape from labs 42 through 44.
   - active: [26, 29, 34, 37]

The network base: VNet on 10.251 slash 16, subnet snet web. Familiar shape from labs 42 through 44.

---

## S008 — CODE

**Steps:**

1. The NSG with an SSH rule — needed so the provisioner's SSH connection can reach the VM. Allow dash SSH, priority 200, destination port 22. And the comment's honest note: it is never associated with the subnet in this lab — with no NSG attached, nothing filters, so the connection works anyway; the rule is scaffolding.
   - active: [42, 43, 47, 53]

The NSG with an SSH rule — needed so the provisioner's SSH connection can reach the VM. Allow dash SSH, priority 200, destination port 22. And the comment's honest note: it is never associated with the subnet in this lab — with no NSG attached, nothing filters, so the connection works anyway; the rule is scaffolding.

---

## S009 — CODE

**Steps:**

1. The public IP is static and standard — and its comment says why: the provisioner's connection host is this VM's public IP. The NIC binds subnet and public IP, the lab-44 pattern.
   - active: [61, 64, 77]

The public IP is static and standard — and its comment says why: the provisioner's connection host is this VM's public IP. The NIC binds subnet and public IP, the lab-44 pattern.

---

## S010 — CODE

**Steps:**

1. The VM block: vm dash provisioner, the standard anatomy — and the admin ssh key fed from var dot admin public key. Everything above is standard; the interesting part is at the bottom.
   - active: [84, 90, 92]
2. The provisioner: remote-exec, with an inline list — apt-get update, then cat the os-release file. Two commands, run over SSH, ONCE, at create time. The comment is the course's position: a provisioner only for steps nothing else can do — never for normal software installs.
   - active: [111, 112, 113, 114]
3. And the connection block: type ssh, host equals self dot public ip address — self is THIS resource, so the host is the VM's own public IP — and private key from var dot admin private key. Terraform signs in as azureadmin and runs the two commands.
   - active: [117, 118, 119, 120, 121]

The VM block: vm dash provisioner, the standard anatomy — and the admin ssh key fed from var dot admin public key. Everything above is standard; the interesting part is at the bottom. The provisioner: remote-exec, with an inline list — apt-get update, then cat the os-release file. Two commands, run over SSH, ONCE, at create time. The comment is the course's position: a provisioner only for steps nothing else can do — never for normal software installs. And the connection block: type ssh, host equals self dot public ip address — self is THIS resource, so the host is the VM's own public IP — and private key from var dot admin private key. Terraform signs in as azureadmin and runs the two commands.

---

## S011 — CONCEPT: Provisioner semantics

- Runs ONCE at create (or destroy) — never re-run on later applies
- Invisible in plan; not idempotent; failure TAINTS the resource
- Prefer cloud-init (lab 40) or a config manager (Ansible, Chef)

**Provisioner semantics**

Here are the semantics that make provisioners a last resort. One: they run once, at create time — a later apply does not re-run them, so configuration drifts from reality after day one. Two: they're invisible in the plan — terraform plan shows that a provisioner exists, but not what it will do; there's no dry-run for the script. Three: if the provisioner fails, the resource is created but TAINTED — Terraform marks it for replacement, even though the VM itself may be perfectly fine. Compare cloud-init from lab 40: declarative, visible in the config, idempotent at first boot. Prefer it — reach for provisioners only when nothing declarative can do the job.

---

## S012 — DIAGRAM: How the pieces connect

**How the pieces connect**

**Steps:**

1. Here's how the pieces connect.
2. Two sensitive variables: the public half the VM trusts, the private half Terraform signs with.
   - active: ['vars']
3. The network: VNet, subnet — and an unassociated NSG.
   - active: ['vnet']
4. The public IP — static — is the provisioner's SSH target.
   - active: ['pip', 'nic']
5. The VM: public key from one variable — and the provisioner connects over SSH using the private half and self dot public ip address.
   - active: ['vm']
6. Everything lands inside your Azure subscription.

Here's how the pieces connect. Two sensitive variables: the public half the VM trusts, the private half Terraform signs with. The network: VNet, subnet — and an unassociated NSG. The public IP — static — is the provisioner's SSH target. The VM: public key from one variable — and the provisioner connects over SSH using the private half and self dot public ip address. Everything lands inside your Azure subscription.

---

## S013 — TERMINAL

Here's the plan — terraform plan, an illustrative view. Seven to add: resource group, VNet, subnet, NSG, public IP, NIC, VM. The VM's SSH key shows as a sensitive value — and note what the plan does NOT show: the provisioner's commands. Provisioners are invisible in the plan; the script runs after the VM exists.

---

## S014 — TERMINAL

And after apply — terraform output public ip, an illustrative view. The provisioner has already run: apt-get updated, os-release printed — over SSH, from the machine running Terraform. The output value is the same public IP the connection block used.

---

## S015 — CONCEPT: Common pitfall

- Last resort only: not in plan, not idempotent, failure taints the resource
- connection host = self.public_ip_address — the public IP must exist first
- The NSG is unassociated — the rule is scaffolding until it's attached

**Common pitfall**

Three pitfalls. One: the last-resort rule has teeth — provisioners aren't in the plan, don't re-run, and their failure taints the resource. If a declarative path exists — cloud-init, templatefile, Ansible — take it. Two: the connection block's host is self dot public ip address — that's the reference that orders the public IP before the provisioner; break the reference and the SSH connection has no host. Three: the NSG here is created but never associated — the provisioner's SSH works only because NOTHING filters traffic yet; attach the NSG in a later lab and Allow-SSH becomes the thing keeping the connection alive.

---

## S016 — RECAP

- provisioner "remote-exec" runs once at create time, over SSH
- connection { host = self.public_ip_address } — self is this resource
- admin_public_key (VM trusts) vs admin_private_key (Terraform signs)
- Not in plan, not idempotent, failure taints — hence LAST RESORT
- Prefer cloud-init (lab 40) / configuration management for real installs

Quick recap — five things. One: remote-exec runs once, at create time, over SSH, from the machine running Terraform. Two: the connection block targets self dot public ip address, signing with the private key variable. Three: the keypair discipline — public half trusted by the VM, private half held by Terraform; two variables, on purpose. Four: the semantics that make this a last resort — invisible in plan, no re-runs, taint on failure. Five: the right order of tools — cloud-init first, provisioner only when nothing declarative can do it. Now you know the mechanism AND the warning label.

---

## S017 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

---

## S018 — CONCEPT: Thanks for watching

**Thanks for watching**

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-02-meta-arguments/45-provisioners
```

Thanks for watching. If this helped, the full lab — along with every lab in this course — is in the GitHub repository linked in the description. See you in the next one.

---
