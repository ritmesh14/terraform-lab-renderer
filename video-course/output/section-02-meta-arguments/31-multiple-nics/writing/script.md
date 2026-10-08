# Script — Lab 31: A Map Built While You Watch: for_each over Computed Values

*Terraform Meta-arguments — Lab 31. Generated from `source/terraform-inventory.json` + `source/source-manifest.json` (ACTIVE_LAB = `section-02-meta-arguments/31-multiple-nics`).*

---

## S001 — TITLE: A Map Built While You Watch: for_each over Computed Values

**A Map Built While You Watch: for_each over Computed Values**

Welcome back. So far, for_each has iterated collections you wrote by hand — a toset, a map in locals. But what if the map doesn't exist until the configuration runs? This is Lab 31, and we let Terraform build the map: a for expression computes one subnet CIDR per tier, and for_each consumes it. Then we go one step further — iterating a map of already-created resources. Let's build it.

---

## S002 — CONCEPT: What you'll learn

- A for expression can BUILD the map for_each consumes
- for_each over a resource map — each.value is a whole object
- keys() reads the instance keys back out

**What you'll learn**

Three things in this lesson. One: a for expression that builds the map for_each consumes — we start from a plain list of tier names and compute a CIDR for each one on the fly. Two: for_each over a resource map — when the collection is other resource instances, each dot value isn't a string, it's a whole object with every attribute. Three: keys, to read the instance keys back out of the finished map.

---

## S003 — CONCEPT: Where this lab fits

- Labs 28–30: for_each over sets and maps you wrote
- This lab: the collection is computed — and can be resources
- Next: for_each driven straight from input variables

**Where this lab fits**

Quick placement. Labs 28 through 30 taught for_each over collections you wrote yourself — a toset of names, maps of files and subnets. This lab removes the constraint that the collection must exist before you type it: a for expression computes it from another list. And the second half goes further — the collection is the map of subnets Terraform itself created. The lab after this drives for_each straight from an input variable.

---

## S004 — CONCEPT: Where to find this lab

**Where to find this lab**

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-02-meta-arguments
          └── 31-multiple-nics

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-02-meta-arguments/31-multiple-nics
```

You'll find this lab in the course GitHub repository under Section 2, Meta-arguments — the lab named 31-multiple-nics. The direct link is in the video description. Two files matter: main dot T F holds the whole configuration, and terraform dot T F pins the providers.

---

## S005 — CODE

Two files matter here, and the first is terraform dot T F. It pins the tooling: Terraform 1.5 or newer, and the azurerm provider around version 3.70 — nothing else, because this lab needs no extras. The provider block at the bottom is the bridge to Azure; the empty features block enables the provider's default behaviours. That's the whole file — every interesting line lives in main dot T F.

---

## S006 — CODE

The raw material is the smallest collection in the course so far: a locals block holding one list — tiers: web, app, data. Just three plain strings. No CIDRs anywhere yet — those get computed in a moment. Notice the comment: this is deliberately a list, not a set, because the next scene needs the numeric index each element sits at.

---

## S007 — CODE

**Steps:**

1. The resource group is the usual container — rg dash multi dash nics.
   - active: [12, 13, 14, 15]
2. The virtual network gets one slash 16 address space, 10.160 slash 16. Every subnet we're about to compute must fit inside that space — and they will, each one is a slash 24.
   - active: [18, 19, 20, 21, 22, 23]

The resource group is the usual container — rg dash multi dash nics. The virtual network gets one slash 16 address space, 10.160 slash 16. Every subnet we're about to compute must fit inside that space — and they will, each one is a slash 24.

---

## S008 — CODE

**Steps:**

1. Here is the star: one subnet block, and its for_each is not a variable or a locals map — it's a for expression, written inline. For each element t of local dot tiers, with its index i, produce a key t and a value — the CIDR string built from i plus one.
   - active: [28]
2. Read the result as a map: web maps to 10.160.1.0 slash 24, app to 10.160.2.0 slash 24, data to 10.160.3.0 slash 24. The interpolation dollar-brace i plus one is what turns an index into an octet.
   - active: [28]
3. Inside the block, each dot key is the tier name — it names the subnet — and each dot value is the computed CIDR. One block, three subnets, and the addressing was never hand-written.
   - active: [29, 32]

Here is the star: one subnet block, and its for_each is not a variable or a locals map — it's a for expression, written inline. For each element t of local dot tiers, with its index i, produce a key t and a value — the CIDR string built from i plus one. Read the result as a map: web maps to 10.160.1.0 slash 24, app to 10.160.2.0 slash 24, data to 10.160.3.0 slash 24. The interpolation dollar-brace i plus one is what turns an index into an octet. Inside the block, each dot key is the tier name — it names the subnet — and each dot value is the computed CIDR. One block, three subnets, and the addressing was never hand-written.

---

## S009 — FOR_EACH_MAP: A list becomes a computed map, then keyed instances

**A list becomes a computed map, then keyed instances**

**Steps:**

1. The input is a plain list — web, app, data. A list has order, and that's exactly what we need, because the index drives the second octet.
2. The for expression walks it and emits a map: each tier paired with its computed CIDR. This map never existed in the source — Terraform built it while evaluating.
3. for_each consumes the map and expands the one block into one instance per key — the addresses are the tier names.
4. And the names follow the keys: snet dash web, snet dash app, snet dash data. The list order decided the octets; the keys decided the addresses.

The input is a plain list — web, app, data. A list has order, and that's exactly what we need, because the index drives the second octet. The for expression walks it and emits a map: each tier paired with its computed CIDR. This map never existed in the source — Terraform built it while evaluating. for_each consumes the map and expands the one block into one instance per key — the addresses are the tier names. And the names follow the keys: snet dash web, snet dash app, snet dash data. The list order decided the octets; the keys decided the addresses.

---

## S010 — CODE

**Steps:**

1. Now the second trick: the NIC block's for_each iterates azurerm_subnet dot this — not a variable, not a locals map, but the map of subnet instances Terraform is creating. One NIC per subnet, keys inherited.
   - active: [37, 38, 39]
2. Because the collection is a resource map, each dot value is a whole subnet object — every attribute of the created subnet. We only need one: each dot value dot id drops straight into the ip configuration's subnet id.
   - active: [44]
3. The dependency is implicit and automatic: a NIC can't be planned until its subnet exists in the graph, so Terraform orders subnet first, NIC second — three times over, once per key.
   - active: [40, 41, 42, 43, 44, 45, 46]

Now the second trick: the NIC block's for_each iterates azurerm_subnet dot this — not a variable, not a locals map, but the map of subnet instances Terraform is creating. One NIC per subnet, keys inherited. Because the collection is a resource map, each dot value is a whole subnet object — every attribute of the created subnet. We only need one: each dot value dot id drops straight into the ip configuration's subnet id. The dependency is implicit and automatic: a NIC can't be planned until its subnet exists in the graph, so Terraform orders subnet first, NIC second — three times over, once per key.

---

## S011 — CODE

**Steps:**

1. The output reads the fan-out back. keys on the NIC resource map returns the key list — nic names in the same keys the subnets used: app, data, web.
   - active: [50]
2. Note the order in that output — keys of a map come back sorted, not in source order. Web, app, data went in; app, data, web comes out. Maps have no order — that's by design.
   - active: [50]

The output reads the fan-out back. keys on the NIC resource map returns the key list — nic names in the same keys the subnets used: app, data, web. Note the order in that output — keys of a map come back sorted, not in source order. Web, app, data went in; app, data, web comes out. Maps have no order — that's by design.

---

## S012 — DIAGRAM: How the pieces connect

**How the pieces connect**

**Steps:**

1. Here's how the pieces connect.
2. Locals hold the tiers list — web, app, data.
   - active: ['locals']
3. The resource group groups everything in Azure.
   - active: ['rg']
4. The virtual network carves the 10.160 slash 16 space.
   - active: ['vnet']
5. The subnets: a for expression turns the tiers list into a tier-to-CIDR map, and for_each expands it into three keyed subnets inside the VNet.
   - active: ['subnets']
6. The NICs iterate the subnet map itself — one NIC per subnet key, each wired to its own subnet's id.
   - active: ['nics']
7. The output lists the keys back — one NIC per tier.
   - active: ['out']
8. Everything lands inside your Azure subscription.

Here's how the pieces connect. Locals hold the tiers list — web, app, data. The resource group groups everything in Azure. The virtual network carves the 10.160 slash 16 space. The subnets: a for expression turns the tiers list into a tier-to-CIDR map, and for_each expands it into three keyed subnets inside the VNet. The NICs iterate the subnet map itself — one NIC per subnet key, each wired to its own subnet's id. The output lists the keys back — one NIC per tier. Everything lands inside your Azure subscription.

---

## S013 — TERMINAL

Here's the plan — terraform plan, an illustrative view. Count the entries: the resource group, the virtual network, three keyed subnets — subnet this in brackets app, data, web — and three keyed NICs with the same keys. Eight to add, zero to destroy. Two blocks of fan-out code; eight real resources.

---

## S014 — TERMINAL

And the output — terraform output nics, an illustrative view. The list comes back sorted: app, data, web. Not the order we typed — the order maps keep. Every NIC name is the key it was built from.

---

## S015 — CONCEPT: Common pitfall

- A for expression's keys must be unique — duplicates collide
- Iterating a resource map: each.value is a full object, not a string
- Hand-built ${i+1} octets work, but cidrsubnet() is the real tool

**Common pitfall**

Three pitfalls. One: the map a for expression builds must have unique keys — if two list elements produced the same key, the expression errors out instead of silently dropping one. Two: when for_each iterates a resource map, each dot value is the whole object — a string's dot-value habits will bite you; reach for dot id, dot name, whatever attribute you actually need. Three: this lab hand-builds octets with i plus one for teaching, but real CIDR math belongs to the cidrsubnet function — it handles host bits and sizing for you.

---

## S016 — RECAP

- for_each can consume a map a for expression computes inline
- each.key names the instance; each.value carries the computed value
- for_each over a resource map: one instance per existing key
- each.value.id — a resource object's attributes, not a string
- keys() returns every instance key — sorted, because maps are

Quick recap — five things. One: for_each doesn't need a collection you wrote — a for expression can compute the map inline. Two: each dot key names the instance, each dot value carries what the expression produced. Three: for_each can iterate a resource map — one copy per already-existing key. Four: there, each dot value is a full object, so each dot value dot id feeds references directly. Five: keys lists every key back — sorted, because maps have no order. The collection doesn't have to exist before you write the code — Terraform can build it while it plans.

---

## S017 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

---

## S018 — CONCEPT: Thanks for watching

**Thanks for watching**

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-02-meta-arguments/31-multiple-nics
```

Thanks for watching. If this helped, the full lab — along with every lab in this course — is in the GitHub repository linked in the description. See you in the next one.

---
