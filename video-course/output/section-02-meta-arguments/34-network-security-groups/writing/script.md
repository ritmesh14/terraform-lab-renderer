# Script — Lab 34: One Map, Three Resources: Keys in Lockstep

*Terraform Meta-arguments — Lab 34. Generated from `source/terraform-inventory.json` + `source/source-manifest.json` (ACTIVE_LAB = `section-02-meta-arguments/34-network-security-groups`).*

---

## S001 — TITLE: One Map, Three Resources: Keys in Lockstep

**One Map, Three Resources: Keys in Lockstep**

Welcome back. Lab 33 fed one map to two fan-outs. This is Lab 34, and we push the idea to its conclusion: one map of tier objects drives THREE resources — subnets, NSGs, and the associations between them — all marching on the same keys. The trick that holds it together is a key lookup: this, bracket, each dot key. Let's build it.

---

## S002 — CONCEPT: What you'll learn

- A map of objects — one entry per tier, every field that tier needs
- Three resources iterating the SAME map — keys stay in lockstep
- Cross-lookup by key: azurerm_subnet.this[each.key]

**What you'll learn**

Three things in this lesson. One: a map of objects where each entry carries everything its tier needs — a prefix and a port. Two: three different resources all iterating that same map, so their instance keys stay in lockstep — web everywhere, app everywhere. Three: the cross-lookup — inside one resource, reaching into another by the same key: azurerm_subnet dot this, bracket, each dot key.

---

## S003 — CONCEPT: Where this lab fits

- Lab 33: one input map, two fan-outs (subnets + filtered NSGs)
- This lab: one locals map, three fan-outs — plus a key-based pairing
- The association needs BOTH endpoints — the key lookup wires it

**Where this lab fits**

Placement. Last lab one map fed two fan-outs, and a filter split them. Here the map is back in locals and nothing is filtered — every tier gets a subnet AND an NSG AND an association, all from one entry. The new mechanic is pairing: the association resource needs one subnet and one NSG per tier, and it finds both by looking them up with its own key.

---

## S004 — CONCEPT: Where to find this lab

**Where to find this lab**

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-02-meta-arguments
          └── 34-network-security-groups

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-02-meta-arguments/34-network-security-groups
```

You'll find this lab in the course GitHub repository under Section 2, Meta-arguments — the lab named 34-network-security-groups. The direct link is in the video description. Main dot T F holds everything; terraform dot T F pins the providers.

---

## S005 — CODE

Two files matter here, and the first is terraform dot T F. It pins the tooling: Terraform 1.5 or newer, and the azurerm provider around version 3.70 — nothing else, because this lab needs no extras. The provider block at the bottom is the bridge to Azure; the empty features block enables the provider's default behaviours. That's the whole file — every interesting line lives in main dot T F.

---

## S006 — CODE

**Steps:**

1. One map rules the whole lab: locals dot tiers. Each key is a tier name; each value is an object with the two things that tier needs — a CIDR prefix and an inbound port.
   - active: [11, 12, 13, 14]
2. This is the single source of truth. Three resources downstream will read this same map — add a tier here and all three fan out together; nothing else in the file needs to change.
   - active: [9, 10, 11]

One map rules the whole lab: locals dot tiers. Each key is a tier name; each value is an object with the two things that tier needs — a CIDR prefix and an inbound port. This is the single source of truth. Three resources downstream will read this same map — add a tier here and all three fan out together; nothing else in the file needs to change.

---

## S007 — CODE

**Steps:**

1. The resource group is the usual container — rg dash nsgs dash meta.
   - active: [18, 19, 20, 21]
2. The virtual network spreads 10.180 slash 16 — the /24s the tiers will carve from it (10.180.1 and 10.180.2) both fit.
   - active: [24, 25, 26, 27, 28, 29]

The resource group is the usual container — rg dash nsgs dash meta. The virtual network spreads 10.180 slash 16 — the /24s the tiers will carve from it (10.180.1 and 10.180.2) both fit.

---

## S008 — CODE

**Steps:**

1. Fan-out one: the subnet block iterates local dot tiers. Keys web and app become snet dash web and snet dash app.
   - active: [33, 34]
2. Each dot value is the tier's object — so each dot value dot prefix drops this tier's own CIDR into address_prefixes. The map did the deciding.
   - active: [37]

Fan-out one: the subnet block iterates local dot tiers. Keys web and app become snet dash web and snet dash app. Each dot value is the tier's object — so each dot value dot prefix drops this tier's own CIDR into address_prefixes. The map did the deciding.

---

## S009 — CODE

**Steps:**

1. Fan-out two: the NSG block iterates the SAME map. Same keys, so the NSG instances line up with the subnets — nsg bracket web beside subnet bracket web.
   - active: [42, 43]
2. Inside, one security rule per NSG — and its destination port comes from the map: tostring, each dot value dot port. Web allows 443, app allows 8080 — same code, different values.
   - active: [54]
3. Why tostring? The port in the map is a number; destination_port_range is a string attribute. Terraform refuses to guess the conversion — tostring makes it explicit, and the plan passes.
   - active: [54]

Fan-out two: the NSG block iterates the SAME map. Same keys, so the NSG instances line up with the subnets — nsg bracket web beside subnet bracket web. Inside, one security rule per NSG — and its destination port comes from the map: tostring, each dot value dot port. Web allows 443, app allows 8080 — same code, different values. Why tostring? The port in the map is a number; destination_port_range is a string attribute. Terraform refuses to guess the conversion — tostring makes it explicit, and the plan passes.

---

## S010 — CODE

**Steps:**

1. Fan-out three: the association iterates the same map a third time. One association per tier — the glue that binds an NSG to a subnet.
   - active: [64]
2. And here's the pairing trick: both endpoints are looked up BY KEY. azurerm_subnet dot this, bracket, each dot key — the subnet whose key matches this association's tier. Same expression for the NSG. Web's association gets web's subnet and web's NSG — automatically.
   - active: [65, 66]
3. No indexes, no counting, no ordering — the shared key is the contract. Add a third tier to the map and all three resources grow by one instance each, already wired together.
   - active: [63, 64, 65, 66, 67]

Fan-out three: the association iterates the same map a third time. One association per tier — the glue that binds an NSG to a subnet. And here's the pairing trick: both endpoints are looked up BY KEY. azurerm_subnet dot this, bracket, each dot key — the subnet whose key matches this association's tier. Same expression for the NSG. Web's association gets web's subnet and web's NSG — automatically. No indexes, no counting, no ordering — the shared key is the contract. Add a third tier to the map and all three resources grow by one instance each, already wired together.

---

## S011 — FOR_EACH_MAP: One map, three fan-outs, one key lookup

**One map, three fan-outs, one key lookup**

**Steps:**

1. Everything starts from one map: two tiers, each with a prefix and a port.
2. Fan-out one: for_each over the map gives one subnet per tier — keyed web and app.
3. Fan-out two: the NSG block iterates the same map — same keys, one NSG per tier, each allowing its own port.
4. Fan-out three: the association also iterates the map, and its two endpoints are found by key lookup — bracket each dot key on both sides. The key is the pairing.

Everything starts from one map: two tiers, each with a prefix and a port. Fan-out one: for_each over the map gives one subnet per tier — keyed web and app. Fan-out two: the NSG block iterates the same map — same keys, one NSG per tier, each allowing its own port. Fan-out three: the association also iterates the map, and its two endpoints are found by key lookup — bracket each dot key on both sides. The key is the pairing.

---

## S012 — DIAGRAM: How the pieces connect

**How the pieces connect**

**Steps:**

1. Here's how the pieces connect.
2. Locals hold the tiers map — the single source of truth.
   - active: ['locals']
3. The resource group groups everything in Azure.
   - active: ['rg']
4. The virtual network spreads the 10.180 slash 16 space.
   - active: ['vnet']
5. The subnets: for_each over the map — one per tier, each with its own CIDR.
   - active: ['subnets']
6. The NSGs: for_each over the same map — one per tier, each allowing its tier's port via tostring.
   - active: ['nsgs']
7. And the associations: for_each again, wiring each NSG to its subnet by key lookup — bracket each dot key on both sides.
   - active: ['assoc']
8. Everything lands inside your Azure subscription.

Here's how the pieces connect. Locals hold the tiers map — the single source of truth. The resource group groups everything in Azure. The virtual network spreads the 10.180 slash 16 space. The subnets: for_each over the map — one per tier, each with its own CIDR. The NSGs: for_each over the same map — one per tier, each allowing its tier's port via tostring. And the associations: for_each again, wiring each NSG to its subnet by key lookup — bracket each dot key on both sides. Everything lands inside your Azure subscription.

---

## S013 — TERMINAL

Here's the plan — terraform plan, an illustrative view. The resource group, the VNet, two keyed subnets, two keyed NSGs, and two keyed associations — every resource carrying the same bracket web and bracket app addresses. Seven to add, zero to destroy. One map in the source; three families of copies in the plan.

---

## S014 — TERMINAL

And state confirms the lockstep — terraform state list, an illustrative view. Read the addresses top to bottom: subnet web, subnet app, NSG web, NSG app, association web, association app. The same two keys repeat across three resource types — that's what one map buying three fan-outs looks like in state.

---

## S015 — CONCEPT: Common pitfall

- Every key in the lookup must exist in BOTH maps — or plan errors
- tostring() is required: a number can't drop into a string attribute
- Keep ONE map as the source of truth — don't copy keys per resource

**Common pitfall**

Three pitfalls. One: the key lookup is strict — if the association asks for a key the subnet map doesn't have, Terraform fails the plan with a missing-key error. Keep every consumer on the same map and the keys can't drift. Two: tostring isn't optional styling — a number port into a string attribute is a type error; the explicit call is Terraform telling you types matter. Three: the design rule — one map, one source of truth. The moment you write a second map with 'the same keys', they will drift apart; add the tier once and let every resource follow.

---

## S016 — RECAP

- One map of objects — prefix and port per tier — drives everything
- Three resources for_each over the SAME map: keys in lockstep
- each.value.prefix and tostring(each.value.port) read the entry
- azurerm_subnet.this[each.key] — pairing by key, not by index
- Add a tier to the map: all three resources grow together

Quick recap — five things. One: a single map of objects holds everything each tier needs. Two: three resources iterate that same map, so their instance keys stay in lockstep. Three: each dot value dot prefix and tostring of each dot value dot port read the entry's fields — tostring because the port is a number. Four: the association pairs endpoints by key — bracket each dot key on both sides, no indexes anywhere. Five: add a tier to the map and all three families grow together, already wired. One map, three resources, keys in lockstep.

---

## S017 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

---

## S018 — CONCEPT: Thanks for watching

**Thanks for watching**

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-02-meta-arguments/34-network-security-groups
```

Thanks for watching. If this helped, the full lab — along with every lab in this course — is in the GitHub repository linked in the description. See you in the next one.

---
