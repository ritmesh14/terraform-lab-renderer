# Script — Lab 30: Carving the Network: Subnets from a Map

*Terraform Meta-arguments — Lab 30. Generated from `source/terraform-inventory.json` + `source/source-manifest.json` (ACTIVE_LAB = `section-02-meta-arguments/30-multiple-subnets`).*

---

## S001 — TITLE: Carving the Network: Subnets from a Map

**Carving the Network: Subnets from a Map**

Welcome back to the course. for_each has walked a set and a map of blobs — this is Lab 30, and it's the pattern you'll reuse on almost every Azure network: one virtual network, and four subnets carved out of it by a single for_each over a map. Plus the for expression that turns the instances back into a clean output. Let's build it.

---

## S002 — CONCEPT: What you'll learn

- for_each over a map of tier → CIDR
- each.key names the subnet; each.value sizes it
- The for expression — reshaping a map for an output

**What you'll learn**

Here's what you'll learn — three things. One: for_each over a map of tier to C I D R — the most-reused networking pattern in Terraform. Two: how each dot key and each dot value split the work — the key names the subnet, the value sizes it. Three: the for expression — a compact loop that reshapes the for_each map into exactly the output shape you want.

---

## S003 — CONCEPT: Where this lab fits

- Labs 28–29: for_each over a set, then a map of blobs
- This lab: the production pattern — one VNet, subnets from a map
- Adding a tier = adding one map line

**Where this lab fits**

This is the fifth lab of Section 2, Meta-arguments. Labs 28 and 29 built the for_each foundation — first over a set, then over a map where values carry config. This lab applies it to the pattern you'll meet in almost every real Azure project: one virtual network, and every subnet defined as one line in a map. Add a tier to the map, and the network grows — no new resource blocks.

---

## S004 — CONCEPT: Where to find this lab

**Where to find this lab**

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-02-meta-arguments
          └── 30-multiple-subnets
              ├── README.md
              ├── main.tf
              └── terraform.tf

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-02-meta-arguments/30-multiple-subnets
```

You can find this lab in the course GitHub repository under Section 2, Meta-arguments — the lab named 30-multiple-subnets. The direct link is in the video description. Two files matter in this lesson: main dot T F holds the whole configuration, and terraform dot T F pins the provider.

---

## S005 — CONCEPT: The mental model: one plot of land, fenced lots

- The VNet is the land — one big /16 address space
- Subnets are fenced lots carved out of it
- The locals map is the plot plan: name and size per lot

**The mental model: one plot of land, fenced lots**

Here's the mental model. Picture one plot of land — that's the virtual network, with its big slash sixteen address space. Subnets are the fenced lots carved out of that land — web, app, data, mgmt. And the locals map is the plot plan: each line says a lot's name and its size. Terraform is the surveyor — it reads the plan once and fences every lot. Change the plan, and the next apply re-fences the land.

---

## S006 — CODE

Terraform dot T F pins the tooling: Terraform 1.5 or newer and the azurerm provider around version 3.70 — this lab needs no random provider, since subnet names come straight from the map. The provider block at the bottom is the bridge to Azure; the empty features block enables the provider's default behaviours.

---

## S007 — CODE

**Steps:**

1. The whole fan-out is one locals map. Subnets maps tier names to C I D R blocks — each entry becomes one subnet.
   - active: [7, 8, 9]
2. Read the entries: web gets ten dot one-fifty dot one dot zero slash twenty-four, app the two, data the three, mgmt the four. Four tiers, four lines — that's the entire network design.
   - active: [10, 11, 12, 13, 14]

The whole fan-out is one locals map. Subnets maps tier names to C I D R blocks — each entry becomes one subnet. Read the entries: web gets ten dot one-fifty dot one dot zero slash twenty-four, app the two, data the three, mgmt the four. Four tiers, four lines — that's the entire network design.

---

## S008 — CODE

**Steps:**

1. The resource group gets a fixed name — rg dash multi dash subnets.
   - active: [18, 19, 20, 21]
2. Then the virtual network: one big slash sixteen space, ten dot one-fifty dot zero dot zero slash sixteen. It references the group for its location and name — so the group is always created first.
   - active: [25, 26, 27, 28, 29, 30]

The resource group gets a fixed name — rg dash multi dash subnets. Then the virtual network: one big slash sixteen space, ten dot one-fifty dot zero dot zero slash sixteen. It references the group for its location and name — so the group is always created first.

---

## S009 — CODE

**Steps:**

1. And the fan-out: one subnet block, for_each equals local dot subnets. Four map entries — four subnets, all inside the one VNet.
   - active: [33, 34]
2. The name builds from the key: s-n-e-t dash, then each dot key — snet dash web, snet dash app, snet dash data, snet dash mgmt. The key labels the tier; the prefix keeps them consistent.
   - active: [35]
3. And the size comes from the value: address_prefixes takes a list, so each dot value — the C I D R string — goes inside brackets. That's the one line people forget: it's a list of prefixes, not a single string.
   - active: [36, 37, 38]

And the fan-out: one subnet block, for_each equals local dot subnets. Four map entries — four subnets, all inside the one VNet. The name builds from the key: s-n-e-t dash, then each dot key — snet dash web, snet dash app, snet dash data, snet dash mgmt. The key labels the tier; the prefix keeps them consistent. And the size comes from the value: address_prefixes takes a list, so each dot value — the C I D R string — goes inside brackets. That's the one line people forget: it's a list of prefixes, not a single string.

---

## S010 — FOR_EACH_MAP: One map, one block, four subnets

**One map, one block, four subnets**

**Steps:**

1. The collection is the map — four tiers, each with its own C I D R. The keys will name the subnets; the values will size them.
2. for_each walks the map and expands the one block into one instance per key — four subnets from a single resource block.
3. For each instance, each dot key lands in the name — s-n-e-t dash web and friends — and each dot value becomes the address prefix.
4. The state addresses are the tier names: this in brackets, quote, web, quote. Need the management subnet's ID later? this in brackets mgmt — no counting positions.

The collection is the map — four tiers, each with its own C I D R. The keys will name the subnets; the values will size them. for_each walks the map and expands the one block into one instance per key — four subnets from a single resource block. For each instance, each dot key lands in the name — s-n-e-t dash web and friends — and each dot value becomes the address prefix. The state addresses are the tier names: this in brackets, quote, web, quote. Need the management subnet's ID later? this in brackets mgmt — no counting positions.

---

## S011 — CODE

**Steps:**

1. The output is a for expression. Read it as: for each key k and subnet s in the for_each map, produce k, arrow, s dot id. Old key in, new value out.
   - active: [43, 44]
2. The result is a reshaped map: web maps to that subnet's full Azure ID, app to its own, and so on. Same keys as the locals map — different values: real resource IDs instead of C I D Rs.
   - active: [44]

The output is a for expression. Read it as: for each key k and subnet s in the for_each map, produce k, arrow, s dot id. Old key in, new value out. The result is a reshaped map: web maps to that subnet's full Azure ID, app to its own, and so on. Same keys as the locals map — different values: real resource IDs instead of C I D Rs.

---

## S012 — CONCEPT: The for expression, in one minute

- { for k, v in collection : k => expr } builds a map
- The key stays; the value is whatever expr computes
- Here: subnet key → its full Azure resource ID

**The for expression, in one minute**

A one-minute tour of the for expression, since it appears right in the output. The general shape: curly for, a key and a value name, in a collection, colon, key arrow expression. Terraform walks the collection once per element; the key usually stays the same, and the expression decides the new value. Here the collection is the for_each map, and the expression is s dot id — so tier names in, full Azure resource IDs out. You'll meet this expression again when outputs need reshaping.

---

## S013 — DIAGRAM: How the pieces connect

**How the pieces connect**

**Steps:**

1. Here's how the pieces connect.
2. Locals hold the subnets map — the plot plan.
   - active: ['locals']
3. The resource group groups everything in Azure.
   - active: ['rg']
4. The virtual network references the group, and owns the big slash sixteen space the subnets will carve from.
   - active: ['vnet']
5. And the subnets: for_each walks the map — one subnet per tier, each fenced out of the VNet's space.
   - active: ['subnets']
6. The for expression in the output reshapes the map: tier names in, full subnet IDs out.
   - active: ['out']
7. Everything lands inside your Azure subscription.

Here's how the pieces connect. Locals hold the subnets map — the plot plan. The resource group groups everything in Azure. The virtual network references the group, and owns the big slash sixteen space the subnets will carve from. And the subnets: for_each walks the map — one subnet per tier, each fenced out of the VNet's space. The for expression in the output reshapes the map: tier names in, full subnet IDs out. Everything lands inside your Azure subscription.

---

## S014 — TERMINAL

Here's the plan — terraform plan, an illustrative view. Six to add: the resource group, the virtual network, and four subnets — this in brackets app, brackets data, brackets mgmt, brackets web. One subnet block in the code; four carved subnets in the plan. Add a fifth tier to the map, and this plan grows by exactly one entry.

---

## S015 — TERMINAL

And here's the output after apply — terraform output subnet underscore ids, an illustrative view. The for expression did its reshaping: tier names on the left, full Azure subnet IDs on the right. Downstream modules or configs can now say: give me the web subnet — and read it straight from this map by name.

---

## S016 — CONCEPT: Common pitfall

- address_prefixes is a LIST — wrap each.value in brackets
- Subnets wait for the VNet — the reference orders creation
- CIDRs must not overlap and must sit inside the VNet's space

**Common pitfall**

One pitfall to understand before you carve networks. One: address prefixes is a list — write each dot value alone and the plan fails a type check; it must be bracket, each dot value, bracket. Two: subnets depend on their VNet — here the reference to the VNet's name handles that ordering for you; break the reference and Terraform might race the network. Three: the C I D Rs are your contract — each must sit inside the VNet's slash sixteen, and none may overlap another. Azure rejects collisions at apply time, after the plan already looked green.

---

## S017 — RECAP

- for_each = local.subnets — one subnet per map entry
- each.key names it (snet-web); each.value sizes it
- The state address is the tier: this["web"]
- The for expression reshapes the map into key → id
- Adding a tier is adding one map line

Quick recap — five things. One: for_each equals local dot subnets — one subnet per map entry. Two: each dot key names the subnet, each dot value sizes it. Three: the state address is the tier name — this bracket web — readable and stable. Four: the for expression reshaped the instances into a clean map of tier to full I D. Five: adding a tier is adding one line to the map. One plot of land — fenced exactly as the plan says.

---

## S018 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

---

## S019 — CONCEPT: Thanks for watching

**Thanks for watching**

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-02-meta-arguments/30-multiple-subnets
```

Thanks for watching. If this helped, the full lab — along with every lab in this course — is in the GitHub repository linked in the description. See you in the next one.

---
