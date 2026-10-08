# Script — Lab 36: Spreading the Risk: Availability Sets

*Terraform Meta-arguments — Lab 36. Generated from `source/terraform-inventory.json` + `source/source-manifest.json` (ACTIVE_LAB = `section-02-meta-arguments/36-availability-sets`).*

---

## S001 — TITLE: Spreading the Risk: Availability Sets

**Spreading the Risk: Availability Sets**

Welcome back. Lab 35 taught count's classic idiom — two resources paired by index. This is Lab 36, and it adds the piece every real VM fleet needs: an availability set. Two counted VMs, and both point at ONE shared resource — so Azure spreads them across separate hardware. One resource, referenced by every instance. Let's build it.

---

## S002 — CONCEPT: What you'll learn

- azurerm_availability_set — fault domains + update domains, declared
- Both counted VMs share ONE availability_set_id
- 99.95% SLA — within a single datacenter, when VMs span the domains

**What you'll learn**

Three things in this lesson. One: the availability set resource — you declare how many fault domains and update domains it offers. Two: the shared reference — both counted VMs point at the same availability set id, and that's what makes them spread. Three: the payoff in numbers — VMs spread across fault and update domains within one datacenter take Microsoft's SLA for that pair up to 99.95 percent. No zones involved — that's the next lab.

---

## S003 — CONCEPT: Where this lab fits

- Lab 35: count pairing — VM[i] ↔ NIC[i] by index
- This lab: a third, UNcounted resource both instances reference
- Next: zones — spreading across datacenters, not racks

**Where this lab fits**

Placement. Lab 35 built the count pairing: VM i uses NIC i. This lab keeps that pairing and adds a third resource that is NOT counted — one availability set, created once, referenced by every VM instance. The mental model shifts from 'copies that pair' to 'copies that share'. The next lab goes bigger: availability zones, which spread VMs across whole datacenters instead of racks.

---

## S004 — CONCEPT: Where to find this lab

**Where to find this lab**

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-02-meta-arguments
          └── 36-availability-sets

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-02-meta-arguments/36-availability-sets
```

You'll find this lab in the course GitHub repository under Section 2, Meta-arguments — the lab named 36-availability-sets. The direct link is in the video description. Main dot T F holds everything, including the variables; terraform dot T F pins the providers.

---

## S005 — CODE

Terraform dot T F pins the tooling: Terraform 1.5 or newer, and the azurerm provider around version 3.70 — no extra providers this time. The provider block at the bottom bridges to Azure; the empty features block enables the provider's defaults. Every interesting line lives in main dot T F.

---

## S006 — CODE

**Steps:**

1. The one input: admin SSH key — a required sensitive string, exactly the pattern from lab 35. No default, so Terraform prompts, and sensitive keeps it out of the plan output.
   - active: [10, 11, 12, 13]
2. The resource group is the container — rg dash availset. Everything this lab creates lands inside it.
   - active: [15, 16, 17, 18]

The one input: admin SSH key — a required sensitive string, exactly the pattern from lab 35. No default, so Terraform prompts, and sensitive keeps it out of the plan output. The resource group is the container — rg dash availset. Everything this lab creates lands inside it.

---

## S007 — CODE

**Steps:**

1. The availability set is ONE resource — no count, no for_each. Created exactly once, named as dash web.
   - active: [22, 23, 24, 25]
2. And its two numbers are the whole point: platform fault domain count 2 — two separate power and network groups, so one hardware failure can't take both VMs. Platform update domain count 5 — five patch waves, so reboots never hit both VMs at once.
   - active: [26, 27]

The availability set is ONE resource — no count, no for_each. Created exactly once, named as dash web. And its two numbers are the whole point: platform fault domain count 2 — two separate power and network groups, so one hardware failure can't take both VMs. Platform update domain count 5 — five patch waves, so reboots never hit both VMs at once.

---

## S008 — CODE

**Steps:**

1. The network base is familiar from lab 35: virtual network on 10.200 slash 16, one subnet — snet web on 10.200.1.0 slash 24. Shared by every counted NIC.
   - active: [35, 40, 43]

The network base is familiar from lab 35: virtual network on 10.200 slash 16, one subnet — snet web on 10.200.1.0 slash 24. Shared by every counted NIC.

---

## S009 — CODE

**Steps:**

1. The NIC block is the count idiom again — count 2, written as a literal this time. Two instances: web bracket zero, web bracket one.
   - active: [48, 49]
2. Both attach to the same subnet with dynamic private IPs — identical copies, exactly what count is for.
   - active: [52, 53, 54, 55, 56]

The NIC block is the count idiom again — count 2, written as a literal this time. Two instances: web bracket zero, web bracket one. Both attach to the same subnet with dynamic private IPs — identical copies, exactly what count is for.

---

## S010 — CODE

**Steps:**

1. The VM block: count 2 again, names vm dash as dash count dot index — the pairing from lab 35 unchanged.
   - active: [61, 62, 67]
2. And the line this lab exists for: availability set id equals azurerm_availability_set dot web dot id. ONE reference, shared by BOTH instances — because it's outside any count block, both VM instances read the same single id. That shared id is what tells Azure: spread these VMs across your fault and update domains.
   - active: [68]
3. Below it, the three nested blocks you know from lab 35: admin SSH key from the sensitive variable, os disk on standard SSD, and the Ubuntu 22.04 source image.
   - active: [69, 73, 77]

The VM block: count 2 again, names vm dash as dash count dot index — the pairing from lab 35 unchanged. And the line this lab exists for: availability set id equals azurerm_availability_set dot web dot id. ONE reference, shared by BOTH instances — because it's outside any count block, both VM instances read the same single id. That shared id is what tells Azure: spread these VMs across your fault and update domains. Below it, the three nested blocks you know from lab 35: admin SSH key from the sensitive variable, os disk on standard SSD, and the Ubuntu 22.04 source image.

---

## S011 — ITERATION_EXPANSION: Two counted resources, one shared set

**Two counted resources, one shared set**

**Steps:**

1. Both counted resources declare count 2 — the same expansion as lab 35.
2. Four instances total: NIC zero paired with VM zero, NIC one paired with VM one.
3. But the availability set is NOT counted — it exists once, and both VM instances reference the same id. Shared, not paired. Azure uses that to spread them.

Both counted resources declare count 2 — the same expansion as lab 35. Four instances total: NIC zero paired with VM zero, NIC one paired with VM one. But the availability set is NOT counted — it exists once, and both VM instances reference the same id. Shared, not paired. Azure uses that to spread them.

---

## S012 — DIAGRAM: How the pieces connect

**How the pieces connect**

**Steps:**

1. Here's how the pieces connect.
2. The variables provide the sensitive SSH key.
   - active: ['vars']
3. The resource group groups everything in Azure.
   - active: ['rg']
4. The availability set: ONE resource, two fault domains, five update domains.
   - active: ['as']
5. The network: VNet and subnet at 10.200.1.0 slash 24.
   - active: ['vnet']
6. Two counted NICs attach to the shared subnet.
   - active: ['nics']
7. Two counted VMs: each pairs with its NIC by index, and BOTH reference the one availability set id — that's the spread.
   - active: ['vms']
8. Everything lands inside your Azure subscription.

Here's how the pieces connect. The variables provide the sensitive SSH key. The resource group groups everything in Azure. The availability set: ONE resource, two fault domains, five update domains. The network: VNet and subnet at 10.200.1.0 slash 24. Two counted NICs attach to the shared subnet. Two counted VMs: each pairs with its NIC by index, and BOTH reference the one availability set id — that's the spread. Everything lands inside your Azure subscription.

---

## S013 — TERMINAL

Here's the plan — terraform plan, an illustrative view. Resource group, availability set as dash web, VNet, subnet, then the counted pairs — NIC bracket zero and one, VM bracket zero and one, each VM showing a sensitive value for the SSH key. Eight to add, zero to destroy. One availability set in the whole plan — created once, referenced twice.

---

## S014 — CONCEPT: Common pitfall

- Every VM must reference the SAME availability_set_id
- Domain counts are declared by you: 2–3 fault, up to 20 update
- A set spreads within ONE datacenter — region outage needs zones

**Common pitfall**

Three pitfalls. One: the spread only happens if every VM references the same availability set id — miss one VM and that instance lives outside the set, sharing no protection at all. Two: the domain counts are declared by you — two to three fault domains is typical, update domains go up to twenty; Azure distributes your VMs across what you declare. Three: keep the promise in scope — a set spreads VMs within ONE datacenter. If the whole region has a problem, no availability set helps; that's exactly what zones are for, and they're next.

---

## S015 — RECAP

- azurerm_availability_set: ONE resource, declared fault + update domains
- platform_fault_domain_count 2 — separate power/network groups
- platform_update_domain_count 5 — separate patch waves
- Both counted VMs share ONE availability_set_id — that's the spread
- 99.95% SLA within one datacenter — zones (next lab) go further

Quick recap — five things. One: the availability set is a single, uncounted resource declaring its domain counts. Two: two fault domains mean separate power and network groups. Three: five update domains mean reboots never hit every VM at once. Four: the magic is the shared reference — both counted VMs read the same availability set id, and that's what spreads them. Five: the payoff is up to 99.95 percent SLA within a single datacenter — and when you need to survive a whole datacenter, zones are next.

---

## S016 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

---

## S017 — CONCEPT: Thanks for watching

**Thanks for watching**

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-02-meta-arguments/36-availability-sets
```

Thanks for watching. If this helped, the full lab — along with every lab in this course — is in the GitHub repository linked in the description. See you in the next one.

---
