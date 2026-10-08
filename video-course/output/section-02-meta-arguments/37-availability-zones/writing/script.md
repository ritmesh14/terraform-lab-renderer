# Script — Lab 37: One VM per Zone: length() and Zone Lookup

*Terraform Meta-arguments — Lab 37. Generated from `source/terraform-inventory.json` + `source/source-manifest.json` (ACTIVE_LAB = `section-02-meta-arguments/37-availability-zones`).*

---

## S001 — TITLE: One VM per Zone: length() and Zone Lookup

**One VM per Zone: length() and Zone Lookup**

Welcome back. Availability sets spread VMs across racks in ONE datacenter. This is Lab 37, and we go one level up: availability zones — whole separate datacenters. And count gets smarter: instead of a magic number, its size comes from a list, and count dot index becomes a LOOKUP into that list. One VM per zone, automatically. Let's build it.

---

## S002 — CONCEPT: What you'll learn

- count = length(local.zones) — the list sizes the fan-out
- count.index as a LOOKUP: local.zones[count.index] gives meaning
- zone pinning + the real 99.99% SLA conditions

**What you'll learn**

Three things in this lesson. One: count driven by length — the zones list decides how many VMs exist; add a zone, get a VM. Two: count dot index used as a lookup — instead of just numbering things, it reaches into the list to fetch each VM's zone. Three: the honest SLA picture — zone pinning counts toward the 99.99 percent VM SLA, but only when you use premium or ultra disks and span two or more zones; with standard SSD storage, like this lab, it alone doesn't qualify.

---

## S003 — CONCEPT: Where this lab fits

- Lab 36: availability sets — racks within ONE datacenter
- This lab: zones — separate datacenters with independent power
- This is the bridge from count to data-driven fan-outs

**Where this lab fits**

Placement. Lab 36 spread VMs across fault domains — racks within a single building. Zones are physically separate datacenters with independent power, network and cooling. A region outage can't touch a VM in another zone. And technically, this lab is the bridge you've been building toward: count sized by a list is the halfway point between count and for_each — the collection, not a number, decides the fan-out.

---

## S004 — CONCEPT: Where to find this lab

**Where to find this lab**

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-02-meta-arguments
          └── 37-availability-zones

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-02-meta-arguments/37-availability-zones
```

You'll find this lab in the course GitHub repository under Section 2, Meta-arguments — the lab named 37-availability-zones. The direct link is in the video description. Main dot T F holds everything; terraform dot T F pins the providers.

---

## S005 — CODE

Terraform dot T F pins the tooling: Terraform 1.5 or newer, and the azurerm provider around version 3.70 — no extra providers this time. The provider block at the bottom bridges to Azure; the empty features block enables the provider's defaults. Every interesting line lives in main dot T F.

---

## S006 — CODE

**Steps:**

1. The same sensitive SSH key variable as labs 35 and 36 — required, no default, hidden in output.
   - active: [11, 12, 13, 14]
2. And the new piece: a locals block holding one list — zones: one, two, three. Three plain numbers, but they carry the whole lab's meaning: this is WHERE the VMs will live. Not how many — where.
   - active: [16, 17, 18]

The same sensitive SSH key variable as labs 35 and 36 — required, no default, hidden in output. And the new piece: a locals block holding one list — zones: one, two, three. Three plain numbers, but they carry the whole lab's meaning: this is WHERE the VMs will live. Not how many — where.

---

## S007 — CODE

**Steps:**

1. The resource group gets a comment that matters: zones need a region that supports them. East US does — pick a region without zones and the plan fails with a clear error.
   - active: [21, 22, 23, 24]
2. The network is the familiar base: VNet on 10.210 slash 16, one subnet snet web. All three VMs — one per zone — attach to this one shared subnet.
   - active: [31, 36, 39]

The resource group gets a comment that matters: zones need a region that supports them. East US does — pick a region without zones and the plan fails with a clear error. The network is the familiar base: VNet on 10.210 slash 16, one subnet snet web. All three VMs — one per zone — attach to this one shared subnet.

---

## S008 — CODE

**Steps:**

1. The NIC block's count is no longer a number: count equals length of local dot zones. The list decides — three entries, three NICs. Add a four to the list and a fourth NIC appears on the next plan.
   - active: [45]
2. The comment above it says exactly that: adding a zone to the list scales NICs and VMs together. One list, two fan-outs, kept in sync by construction.
   - active: [44, 45]

The NIC block's count is no longer a number: count equals length of local dot zones. The list decides — three entries, three NICs. Add a four to the list and a fourth NIC appears on the next plan. The comment above it says exactly that: adding a zone to the list scales NICs and VMs together. One list, two fan-outs, kept in sync by construction.

---

## S009 — ITERATION_EXPANSION: The list sizes the fan-out

**The list sizes the fan-out**

**Steps:**

1. The expression reads a length, not a number: three list entries mean count three.
2. Three instances expand: VM web bracket zero, one, two — the usual count addressing.
3. But each instance's ZONE comes from a lookup: instance zero reads zones bracket zero, which is one. Instance one gets zone two, instance two gets zone three. The index picks the meaning.

The expression reads a length, not a number: three list entries mean count three. Three instances expand: VM web bracket zero, one, two — the usual count addressing. But each instance's ZONE comes from a lookup: instance zero reads zones bracket zero, which is one. Instance one gets zone two, instance two gets zone three. The index picks the meaning.

---

## S010 — CODE

**Steps:**

1. The VM block: the same count — length of the zones list — and a name that already uses the lookup: vm dash az dash local dot zones, bracket, count dot index. VM zero is named vm dash az dash 1, because zones bracket zero is one. The name shows the zone, not the index.
   - active: [58, 59]
2. And here is the pin: zone equals tostring of local dot zones, bracket, count dot index. tostring because the zone attribute is a string and the list holds numbers. This one line places each VM in its own datacenter.
   - active: [62]
3. The rest is the lab-35 anatomy: NIC picked by index — network interface ids bracket count dot index — then the three nested blocks: SSH key, os disk, image.
   - active: [65, 66, 70, 74]

The VM block: the same count — length of the zones list — and a name that already uses the lookup: vm dash az dash local dot zones, bracket, count dot index. VM zero is named vm dash az dash 1, because zones bracket zero is one. The name shows the zone, not the index. And here is the pin: zone equals tostring of local dot zones, bracket, count dot index. tostring because the zone attribute is a string and the list holds numbers. This one line places each VM in its own datacenter. The rest is the lab-35 anatomy: NIC picked by index — network interface ids bracket count dot index — then the three nested blocks: SSH key, os disk, image.

---

## S011 — CONCEPT: count.index as a lookup, not a number

- So far count.index only COUNTED — 0, 1, 2 in names
- Here it LOOKS UP: zones[count.index] fetches each VM's meaning
- This is the bridge to for_each — data decides, not position

**count.index as a lookup, not a number**

Pause on the idea this lab really teaches. Until now, count dot index was just a counter — it numbered NICs and VMs. Here it becomes a lookup: zones bracket count dot index doesn't just label the VM, it decides WHERE the VM lives. The list carries meaning; the index fetches it. And notice what this enables: change the list and both the count and the meaning change together. That's one step away from for_each, where the data itself becomes the key — which is exactly where the course goes next.

---

## S012 — DIAGRAM: How the pieces connect

**How the pieces connect**

**Steps:**

1. Here's how the pieces connect.
2. The sensitive SSH key variable, as before.
   - active: ['vars']
3. Locals hold the zones list — one, two, three.
   - active: ['locals']
4. The resource group — in a region that supports zones.
   - active: ['rg']
5. The network: VNet and subnet shared by all three VMs.
   - active: ['vnet']
6. Three counted NICs — count sized by length of the zones list.
   - active: ['nics']
7. Three counted VMs, each pinned to its own zone by the lookup — zones bracket count dot index — and paired to its NIC by index.
   - active: ['vms']
8. Everything lands inside your Azure subscription.

Here's how the pieces connect. The sensitive SSH key variable, as before. Locals hold the zones list — one, two, three. The resource group — in a region that supports zones. The network: VNet and subnet shared by all three VMs. Three counted NICs — count sized by length of the zones list. Three counted VMs, each pinned to its own zone by the lookup — zones bracket count dot index — and paired to its NIC by index. Everything lands inside your Azure subscription.

---

## S013 — TERMINAL

Here's the plan — terraform plan, an illustrative view. Resource group, VNet, subnet, then three NICs and three VMs — and look at the VM names: vm dash az dash 1, vm dash az dash 2, vm dash az dash 3. The names come from the list values, not the indexes. Nine to add, zero to destroy.

---

## S014 — CONCEPT: Common pitfall

- 99.99% SLA needs premium/ultra disks AND 2+ zones — Standard SSD doesn't qualify
- The zone must exist in your region — plan fails fast otherwise
- zone is a string: tostring() converts the numeric list entry

**Common pitfall**

Three pitfalls. One: the SLA claim has conditions — 99.99 percent for zone-pinned VMs requires premium or ultra disks and VMs spanning two or more zones. This lab uses standard SSD storage deliberately, so it demonstrates the mechanism without claiming the number. Two: not every region has zones — and not every region has three. If the list says three but the region offers two, the plan fails immediately; that's Terraform protecting you before any deploy. Three: the zone attribute is a string, the list holds numbers — tostring makes the conversion explicit, and forgetting it is a type error.

---

## S015 — RECAP

- count = length(local.zones) — the list sizes the fan-out
- count.index becomes a lookup: zones[count.index] = the VM's zone
- VM names show the zone value: vm-az-1, vm-az-2, vm-az-3
- Zones are separate datacenters — a superset of availability sets
- 99.99% SLA is conditional: premium disks + VMs across 2+ zones

Quick recap — five things. One: count reads a length, so the zones list sizes the fan-out. Two: count dot index becomes a lookup into that list — it fetches each VM's zone. Three: the names prove it — vm dash az dash one through three, named from list values. Four: zones are separate datacenters with independent power — a bigger promise than availability sets. Five: the 99.99 percent SLA is conditional — premium disks and VMs across two or more zones. The list is now the source of truth for both how many and where.

---

## S016 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

---

## S017 — CONCEPT: Thanks for watching

**Thanks for watching**

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-02-meta-arguments/37-availability-zones
```

Thanks for watching. If this helped, the full lab — along with every lab in this course — is in the GitHub repository linked in the description. See you in the next one.

---
