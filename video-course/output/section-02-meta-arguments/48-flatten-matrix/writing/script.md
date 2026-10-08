# Script — Lab 48: The Matrix: flatten() into for_each

*Terraform Meta-arguments — Lab 48. Generated from `source/terraform-inventory.json` + `source/source-manifest.json` (ACTIVE_LAB = `section-02-meta-arguments/48-flatten-matrix`).*

---

## S001 — TITLE: The Matrix: flatten() into for_each

**The Matrix: flatten() into for_each**

Welcome back. for_each can only iterate a FLAT collection — and real infrastructure is often a grid. This is Lab 48: regions times tiers, a list of lists built by a nested for expression, then flattened into one list, then turned into a keyed map — and for_each stamps out one subnet per region-tier pair. Three transforms between the variables and the resources. Let's build it.

---

## S002 — CONCEPT: What you'll learn

- A nested `for` builds a list-of-lists — region × tier with a cidr each
- flatten() removes the nesting — the shape for_each demands
- A map keyed "region-tier" makes every combination addressable

**What you'll learn**

Three things in this lesson. One: the nested for expression — for each region, a list of one entry per tier, each carrying region, tier, and a cidrsubnet-carved address; that's a list of lists. Two: flatten — it collapses the nesting into ONE flat list, the only shape for_each accepts. Three: the keyed map — a for expression builds a map whose keys are region dash tier, so every combination is uniquely addressable in state.

---

## S003 — CONCEPT: Where this lab fits

- Lab 28: for_each over a flat set/map — one dimension
- This lab: a TWO-dimensional matrix flattened into for_each
- Lab 33's for-expression maps return — now built from a nested source

**Where this lab fits**

Placement. Lab 28's for_each iterated a flat set — one dimension. This lab is two dimensions: regions and tiers, and every combination becomes a subnet. The bridge is flatten — and the keyed-map technique is the one from lab 33, now built from a computed list instead of a hand-written variable. Add a region or a tier to the inputs, re-apply, and ONLY the missing pairs get created.

---

## S004 — CONCEPT: Where to find this lab

**Where to find this lab**

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-02-meta-arguments
          └── 48-flatten-matrix

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-02-meta-arguments/48-flatten-matrix
```

You'll find this lab in the course GitHub repository under Section 2, Meta-arguments — the lab named 48-flatten-matrix. The direct link is in the video description. One main dot T F — the terraform block is inline at the top.

---

## S005 — CODE

No separate terraform dot T F this time — the tooling block is inline at the top of main dot T F: Terraform 1.5 or newer, and the azurerm provider around version 3.70. The provider block below bridges to Azure; the empty features block enables the provider's defaults.

---

## S006 — CODE

**Steps:**

1. First axis: regions — a list of strings, defaulting to region A and region B. In this illustrative setting they're labels; in a real deployment they'd carry geography. Every entry here becomes one VNet.
   - active: [22, 23, 24]

First axis: regions — a list of strings, defaulting to region A and region B. In this illustrative setting they're labels; in a real deployment they'd carry geography. Every entry here becomes one VNet.

---

## S007 — CODE

**Steps:**

1. Second axis: tiers — web and app. Every tier becomes one subnet INSIDE each region's VNet. Two regions times two tiers: four subnets from two variables.
   - active: [27, 28, 29]

Second axis: tiers — web and app. Every tier becomes one subnet INSIDE each region's VNet. Two regions times two tiers: four subnets from two variables.

---

## S008 — CODE

**Steps:**

1. Locals first hold the per-region address space: region A gets 172.20 slash 20, region B gets 172.21 slash 20. The map lets the nested expression look up each region's block by name.
   - active: [34, 35, 36, 37, 38]

Locals first hold the per-region address space: region A gets 172.20 slash 20, region B gets 172.21 slash 20. The map lets the nested expression look up each region's block by name.

---

## S009 — CODE

**Steps:**

1. The nested for: OUTER loop over regions, INNER loop over tiers with index i. Each entry carries region, tier, and cidr — cidrsubnet takes the region's /20, adds six bits to a /26, and picks block number i. Region A web is 172.20.0.0/26, app is 172.20.0.64/26.
   - active: [41, 42, 43, 46]
2. But that's a list OF LISTS — one inner list per region. And for_each refuses nested lists. So flatten: line 51 collapses the nesting into ONE flat list of four objects. local dot flat is the shape for_each accepts.
   - active: [50, 51]

The nested for: OUTER loop over regions, INNER loop over tiers with index i. Each entry carries region, tier, and cidr — cidrsubnet takes the region's /20, adds six bits to a /26, and picks block number i. Region A web is 172.20.0.0/26, app is 172.20.0.64/26. But that's a list OF LISTS — one inner list per region. And for_each refuses nested lists. So flatten: line 51 collapses the nesting into ONE flat list of four objects. local dot flat is the shape for_each accepts.

---

## S010 — CODE

**Steps:**

1. The resource group — its name comes from local dot rg, which the locals set to rg dash flatten. Everything in this lab lives in it.
   - active: [55, 56, 57, 58]

The resource group — its name comes from local dot rg, which the locals set to rg dash flatten. Everything in this lab lives in it.

---

## S011 — CODE

**Steps:**

1. The VNets: for_each over toset of regions — the lab-28 pattern. Each key names its VNet, vnet dash region A, vnet dash region B, and each pulls its own address space from the region cidr map. One block, two VNets.
   - active: [62, 63, 66]

The VNets: for_each over toset of regions — the lab-28 pattern. Each key names its VNet, vnet dash region A, vnet dash region B, and each pulls its own address space from the region cidr map. One block, two VNets.

---

## S012 — CODE

**Steps:**

1. Now the subnets — and the line the lab turns on. for_each is fed a for EXPRESSION that builds a map: for each s in local dot flat, the key is region dash tier — regionA dash web — and the value is the whole object. Keys must be unique; the compound key is what makes every combination addressable.
   - active: [70, 71, 72]
2. Inside the block, each dot value is the object: the tier names the subnet, the cidr is its prefix — and the VNet lookup is keyed: azurerm virtual network dot this bracket each dot value dot region. Subnets land in the VNet of their OWN region — a keyed reference into another for_each resource.
   - active: [73, 74, 75]

Now the subnets — and the line the lab turns on. for_each is fed a for EXPRESSION that builds a map: for each s in local dot flat, the key is region dash tier — regionA dash web — and the value is the whole object. Keys must be unique; the compound key is what makes every combination addressable. Inside the block, each dot value is the object: the tier names the subnet, the cidr is its prefix — and the VNet lookup is keyed: azurerm virtual network dot this bracket each dot value dot region. Subnets land in the VNet of their OWN region — a keyed reference into another for_each resource.

---

## S013 — CODE

**Steps:**

1. The output prints the keys — one region dash tier pair per subnet created. Four keys: the matrix, made visible.
   - active: [79]

The output prints the keys — one region dash tier pair per subnet created. Four keys: the matrix, made visible.

---

## S014 — FOR_EACH_MAP: flatten(): nested list → flat list → keyed map

**flatten(): nested list → flat list → keyed map**

**Steps:**

1. The nested for produces a list OF LISTS — one inner list per region. That shape is exactly what for_each refuses.
2. flatten removes the nesting: one flat list of four objects, each carrying region, tier and cidr.
3. A for expression turns the flat list into a map keyed region dash tier — unique keys, every combination addressable.
4. And for_each stamps out one subnet per key — four subnets, each in its own region's VNet. Three transforms between the variables and Azure.

The nested for produces a list OF LISTS — one inner list per region. That shape is exactly what for_each refuses. flatten removes the nesting: one flat list of four objects, each carrying region, tier and cidr. A for expression turns the flat list into a map keyed region dash tier — unique keys, every combination addressable. And for_each stamps out one subnet per key — four subnets, each in its own region's VNet. Three transforms between the variables and Azure.

---

## S015 — DIAGRAM: How the pieces connect

**How the pieces connect**

**Steps:**

1. Here's how the pieces connect.
2. The two variables: regions and tiers — the axes of the matrix.
   - active: ['vars']
3. Locals compute everything before any resource runs: region cidrs, the nested matrix, and its flattened form.
   - active: ['locals']
4. The resource group groups it all in Azure.
   - active: ['rg']
5. One VNet per region — for_each over the set of regions, each with its own /20.
   - active: ['vnets']
6. One subnet per pair — for_each over the flattened map, each landing in its own region's VNet.
   - active: ['subnets']
7. Everything lands inside your Azure subscription.

Here's how the pieces connect. The two variables: regions and tiers — the axes of the matrix. Locals compute everything before any resource runs: region cidrs, the nested matrix, and its flattened form. The resource group groups it all in Azure. One VNet per region — for_each over the set of regions, each with its own /20. One subnet per pair — for_each over the flattened map, each landing in its own region's VNet. Everything lands inside your Azure subscription.

---

## S016 — TERMINAL

Here's the plan — terraform plan, an illustrative view. Seven to add: the resource group, TWO VNets keyed by region, and FOUR subnets keyed region dash tier — each with the /26 its cidrsubnet computed. Look at the addresses: two per region, carved in order.

---

## S017 — TERMINAL

And the output — terraform output subnet keys, an illustrative view. Four keys: region A web, region A app, region B web, region B app. Add a third region to the variable, re-apply, and only the two NEW pairs are created — nothing else moves.

---

## S018 — CONCEPT: Common pitfall

- for_each accepts only flat sets/maps — nested lists MUST be flattened first
- Map keys must be unique — the "region-tier" compound key is what makes pairs addressable
- Adding an axis entry creates ONLY the missing pairs — nothing else is touched

**Common pitfall**

Three pitfalls. One: flatten isn't optional decoration — for_each rejects a list of lists outright, and the error message won't say flatten; you have to know the shape rule. Two: keys must be unique — if you key by tier alone, region A web and region B web collide; the compound region dash tier key is what makes each pair distinct. Three: the flip side of the matrix — growing it is additive. Add a region or tier and only the missing combinations are planned; existing subnets keep their addresses because their keys didn't change.

---

## S019 — RECAP

- Nested for expression → list-of-lists of {region, tier, cidr}
- flatten() collapses the nesting — the shape for_each demands
- for_each over a map keyed "${region}-${tier}" — every pair addressable
- cidrsubnet(base, 6, i) carves each tier's /26 from the region's /20
- azurerm_virtual_network.this[each.value.region] — keyed cross-reference

Quick recap — five things. One: a nested for expression built the matrix — a list of lists of region, tier, cidr. Two: flatten collapsed it into the one flat list for_each demands. Three: a for expression keyed it region dash tier, so every combination is addressable in state. Four: cidrsubnet carved each tier's /26 out of its region's /20. Five: the VNet reference is keyed by region — subnets land in their own VNet. Two variables, four subnets, zero repetition.

---

## S020 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

---

## S021 — CONCEPT: Thanks for watching

**Thanks for watching**

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-02-meta-arguments/48-flatten-matrix
```

Thanks for watching. If this helped, the full lab — along with every lab in this course — is in the GitHub repository linked in the description. See you in the next one.

---
