# Script — Lab 44: Full Deployment: Public IP + NSG End to End

*Terraform Meta-arguments — Lab 44. Generated from `source/terraform-inventory.json` + `source/source-manifest.json` (ACTIVE_LAB = `section-02-meta-arguments/44-linux-deployment`).*

---

## S001 — TITLE: Full Deployment: Public IP + NSG End to End

**Full Deployment: Public IP + NSG End to End**

Welcome back. Lab 43 restructured the files; this is Lab 44, and we DEPLOY that structure end to end — with the two pieces every reachable server needs: a static public IP and an SSH rule. At the end of this lab, you can SSH into a machine Terraform built from scratch. Let's build it.

---

## S002 — CONCEPT: What you'll learn

- Deploy the full restructured stack end to end
- Static public IP + NSG with an Allow-SSH rule
- SSH in from the internet: ssh azureadmin@<public_ip>

**What you'll learn**

Three things in this lesson. One: the full stack, deployed — resource group through VM, the lab-43 shape made real. Two: the reachability pair — a static, standard public IP, and an NSG carrying an Allow-SSH rule on port 22. Three: the payoff — terraform output gives you the IP, and you SSH in with the key that was read from id_rsa dot pub.

---

## S003 — CONCEPT: Where this lab fits

- Lab 43: structured files; lab 42: private IP only — no way in
- This lab: the first VM you can SSH into from the internet
- The NSG here is scaffolding — see the pitfall scene

**Where this lab fits**

Placement. Every VM so far — labs 35, 37, 40, 42 — had private IPs only; there was no way in from outside. This lab adds the path in: public IP on the NIC, SSH opened. One honest note up front, straight from the README: the NSG in this lab is created but left UNASSOCIATED — with no NSG attached, Azure filters nothing at all, so SSH works; making the rule load-bearing comes later. Scaffolding now, wiring soon.

---

## S004 — CONCEPT: Where to find this lab

**Where to find this lab**

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-02-meta-arguments
          └── 44-linux-deployment

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-02-meta-arguments/44-linux-deployment
```

You'll find this lab in the course GitHub repository under Section 2, Meta-arguments — the lab named 44-linux-deployment. The direct link is in the video description. The stack spans main dot T F, locals dot T F and outputs dot T F.

---

## S005 — CODE

Terraform dot T F pins the tooling: Terraform 1.5 or newer, and the azurerm provider around version 3.70 — no extra providers this time. The provider block at the bottom bridges to Azure; the empty features block enables the provider's defaults.

---

## S006 — CODE

**Steps:**

1. locals dot T F carries two values over from the restructure: the SSH key read from disk — same ternary as labs 42 and 43 — and the resource group name.
   - active: [3, 4, 5]

locals dot T F carries two values over from the restructure: the SSH key read from disk — same ternary as labs 42 and 43 — and the resource group name.

---

## S007 — CODE

**Steps:**

1. The network base in main dot T F: resource group from local dot rg, VNet on 10.250 slash 16, subnet snet web on 10.250.1 slash 24. The lab-43 shape, deployed.
   - active: [4, 10, 13, 21]

The network base in main dot T F: resource group from local dot rg, VNet on 10.250 slash 16, subnet snet web on 10.250.1 slash 24. The lab-43 shape, deployed.

---

## S008 — CODE

**Steps:**

1. The NSG with one rule: allow SSH. Name Allow dash SSH, priority 200, inbound TCP, destination port 22. The comment repeats the production advice: tighten the source address prefix to YOUR IP — a star means the whole internet.
   - active: [25, 26, 30, 36]
2. And the README's honest note: this NSG is never associated with the subnet — no subnet or NIC references it in this lab. With nothing attached, Azure filters no traffic at all, so SSH works; attaching the NSG — making the rule load-bearing — is deliberately left for later.
   - active: [25, 26]

The NSG with one rule: allow SSH. Name Allow dash SSH, priority 200, inbound TCP, destination port 22. The comment repeats the production advice: tighten the source address prefix to YOUR IP — a star means the whole internet. And the README's honest note: this NSG is never associated with the subnet — no subnet or NIC references it in this lab. With nothing attached, Azure filters no traffic at all, so SSH works; attaching the NSG — making the rule load-bearing — is deliberately left for later.

---

## S009 — CODE

**Steps:**

1. The public IP: pip dash deploy, static allocation on the standard SKU — the address survives reboots and redeploys, which is exactly what you want for an SSH target you'll type by hand.
   - active: [44, 47, 48]
2. And the NIC binds BOTH: the subnet for the private side, and — inside ip configuration — public ip address id equals azurerm public ip dot web dot id. The pattern from lab 40, now load-bearing: this is the line that makes the VM reachable.
   - active: [56, 58, 60]

The public IP: pip dash deploy, static allocation on the standard SKU — the address survives reboots and redeploys, which is exactly what you want for an SSH target you'll type by hand. And the NIC binds BOTH: the subnet for the private side, and — inside ip configuration — public ip address id equals azurerm public ip dot web dot id. The pattern from lab 40, now load-bearing: this is the line that makes the VM reachable.

---

## S010 — CODE

**Steps:**

1. The VM: vm dash deploy, standard burstable size, admin username azureadmin, NIC from the block above — the lab-43 anatomy unchanged.
   - active: [66, 71]
2. And the key: public key equals local dot ssh pubkey — the file content read in locals dot T F. THIS is the key half that lets you in; the private half is the id_rsa file that never left your machine.
   - active: [72, 73, 74]
3. Below: os disk on standard SSD, Ubuntu 22.04 image — and the output at the bottom prints the public IP, unknown until apply completes.
   - active: [76, 80]

The VM: vm dash deploy, standard burstable size, admin username azureadmin, NIC from the block above — the lab-43 anatomy unchanged. And the key: public key equals local dot ssh pubkey — the file content read in locals dot T F. THIS is the key half that lets you in; the private half is the id_rsa file that never left your machine. Below: os disk on standard SSD, Ubuntu 22.04 image — and the output at the bottom prints the public IP, unknown until apply completes.

---

## S011 — CODE

**Steps:**

1. The whole outputs file: one line. The public IP is known after apply — Azure assigns it — so it prints only when the deployment is done. That value is your SSH target.
   - active: [1, 2]

The whole outputs file: one line. The public IP is known after apply — Azure assigns it — so it prints only when the deployment is done. That value is your SSH target.

---

## S012 — DIAGRAM: How the pieces connect

**How the pieces connect**

**Steps:**

1. Here's how the pieces connect.
2. Locals read the SSH key from disk and name the resource group.
   - active: ['locals']
3. The network: VNet and subnet at 10.250.1.0 slash 24.
   - active: ['vnet']
4. The NSG with the Allow-SSH rule — created but unassociated in this lab.
   - active: ['nsg']
5. The public IP — static, standard — attaches inside the NIC's ip configuration.
   - active: ['pip', 'nic']
6. And the VM: NIC attached, SSH key from the file read — reachable from the internet at that public IP.
   - active: ['vm']
7. Everything lands inside your Azure subscription.

Here's how the pieces connect. Locals read the SSH key from disk and name the resource group. The network: VNet and subnet at 10.250.1.0 slash 24. The NSG with the Allow-SSH rule — created but unassociated in this lab. The public IP — static, standard — attaches inside the NIC's ip configuration. And the VM: NIC attached, SSH key from the file read — reachable from the internet at that public IP. Everything lands inside your Azure subscription.

---

## S013 — TERMINAL

Here's the plan — terraform plan, an illustrative view. Resource group, VNet, subnet, NSG, public IP, NIC, VM — seven to add, zero to destroy. The SSH key shows redacted as a sensitive value in this illustrative view.

---

## S014 — TERMINAL

And after apply — terraform output public ip, an illustrative view. The address is assigned by Azure; ssh azureadmin at that address, with the id_rsa private key on your machine, lands you on the VM.

---

## S015 — CONCEPT: Common pitfall

- The NSG is created but NOT associated — no filtering until it's attached
- source_address_prefix "*" means SSH open to the whole internet
- A static public IP is stable — and a fixed, scanable target

**Common pitfall**

Three pitfalls. One: the unassociated NSG — it exists, its rule says allow SSH, but nothing references it, so no filtering happens at all. The VM is reachable because NOTHING is filtering, not because the rule worked. Attach it and the rule becomes load-bearing. Two: the rule's source address prefix is a star — SSH open to the entire internet. Real deployments tighten it to your IP; the comment in the lab says exactly that. Three: the static public IP is convenient — and permanent. It's a scanable target that survives reboots; treat it as exposure, not just a convenience.

---

## S016 — RECAP

- The lab-43 stack deployed end to end — 7 resources, one apply
- pip-deploy: Static / Standard — survives reboots, stable SSH target
- public_ip_address_id in the NIC's ip_configuration (lab 40 pattern)
- NSG Allow-SSH rule created but unassociated (later lab wires it)
- ssh azureadmin@<public_ip> — key read from id_rsa.pub at plan time

Quick recap — five things. One: the full stack deployed — seven resources, one apply. Two: the public IP is static on the standard SKU — a stable SSH target. Three: it attaches inside the NIC's ip configuration — the lab-40 pattern, now load-bearing. Four: the NSG with its Allow-SSH rule exists but is deliberately unassociated — remember that no filtering happens until it's wired. Five: the key that opened the door was read from id_rsa dot pub at plan time. Terraform built a server you can reach.

---

## S017 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

---

## S018 — CONCEPT: Thanks for watching

**Thanks for watching**

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-02-meta-arguments/44-linux-deployment
```

Thanks for watching. If this helped, the full lab — along with every lab in this course — is in the GitHub repository linked in the description. See you in the next one.

---
