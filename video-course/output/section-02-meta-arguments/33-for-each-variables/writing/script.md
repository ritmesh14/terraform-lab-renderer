# Script — Lab 33: The Config Is the Input: for_each over a Variable

*Terraform Meta-arguments — Lab 33. Generated from `source/terraform-inventory.json` + `source/source-manifest.json` (ACTIVE_LAB = `section-02-meta-arguments/33-for-each-variables`).*

---

## S001 — TITLE: The Config Is the Input: for_each over a Variable

**The Config Is the Input: for_each over a Variable**

Welcome back. Every fan-out so far was written into the code. This is Lab 33, and the collection moves out of the source: a typed map variable, filled from a tfvars file, drives for_each. And then a filter — one for expression keeps only the tiers that actually want an NSG. Same code, different input, different result. Let's build it.

---

## S002 — CONCEPT: What you'll learn

- map(object({...})) — a typed variable where every value is a shape
- for_each over var.subnets — the caller decides the fan-out
- A filtered for_each: `if v.nsg` keeps only matching entries

**What you'll learn**

Three things in this lesson. One: map of object — a variable whose type says every value must carry a prefix and a boolean; Terraform rejects anything else. Two: for_each over var dot subnets — the code doesn't know how many subnets exist; the input decides. Three: a filtered for_each — a for expression with an if clause that keeps only the entries where nsg is true.

---

## S003 — CONCEPT: Where this lab fits

- Labs 28–31: collections written in locals or computed inline
- This lab: the collection is an INPUT — typed and caller-supplied
- Next: one map drives THREE resources in sync

**Where this lab fits**

Placement. Until now every collection lived in the code — a toset, a locals map, a computed map. This lab moves the collection into an input variable, typed strictly, supplied by whoever runs Terraform. That's the hand-off point: configuration becomes data. The next lab takes one map and drives three different resources with it, keys in lockstep.

---

## S004 — CONCEPT: Where to find this lab

**Where to find this lab**

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-02-meta-arguments
          └── 33-for-each-variables

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-02-meta-arguments/33-for-each-variables
```

You'll find this lab in the course GitHub repository under Section 2, Meta-arguments — the lab named 33-for-each-variables. The direct link is in the video description. Three files matter: main dot T F, terraform dot T F for the providers, and terraform dot tfvars — the file that supplies the map.

---

## S005 — CODE

Two files matter here, and the first is terraform dot T F. It pins the tooling: Terraform 1.5 or newer, and the azurerm provider around version 3.70 — nothing else, because this lab needs no extras. The provider block at the bottom is the bridge to Azure; the empty features block enables the provider's default behaviours. That's the whole file — every interesting line lives in main dot T F.

---

## S006 — CODE

**Steps:**

1. The variable's type is the interesting part: map, of object — and the object's shape is spelled out in braces: a prefix, which is a string, and nsg, which is a boolean.
   - active: [7, 8, 9, 10]
2. That type is a contract. Whoever fills this map must give every entry exactly those two fields — miss one, or sneak in a third, and Terraform refuses the value at plan time, before anything is touched.
   - active: [6, 11]

The variable's type is the interesting part: map, of object — and the object's shape is spelled out in braces: a prefix, which is a string, and nsg, which is a boolean. That type is a contract. Whoever fills this map must give every entry exactly those two fields — miss one, or sneak in a third, and Terraform refuses the value at plan time, before anything is touched.

---

## S007 — CODE

**Steps:**

1. Here's the caller's side — terraform dot tfvars. The map holds three tiers: web, app, and data. Web and app set nsg true; data sets it false. That one boolean is about to decide which tiers get firewalls.
   - active: [2, 3, 4, 5, 6]
2. Notice what this means for reuse: adding a tier is now an edit to a data file, not to code. The main dot T F we're about to read never changes when the deployment grows.
   - active: [2]

Here's the caller's side — terraform dot tfvars. The map holds three tiers: web, app, and data. Web and app set nsg true; data sets it false. That one boolean is about to decide which tiers get firewalls. Notice what this means for reuse: adding a tier is now an edit to a data file, not to code. The main dot T F we're about to read never changes when the deployment grows.

---

## S008 — CODE

**Steps:**

1. The resource group is the usual container — rg dash foreach dash vars.
   - active: [14, 15, 16, 17]
2. The virtual network keeps the familiar /16 umbrella — 10.170 slash 16 — wide enough for every subnet the caller might add.
   - active: [20, 21, 22, 23, 24, 25]

The resource group is the usual container — rg dash foreach dash vars. The virtual network keeps the familiar /16 umbrella — 10.170 slash 16 — wide enough for every subnet the caller might add.

---

## S009 — CODE

**Steps:**

1. The subnet block's for_each is the shortest one yet: var dot subnets, straight from input to fan-out. One subnet per key — web, app, data.
   - active: [29]
2. Each dot key names the subnet — snet dash web and so on — and each dot value is the object from the map, so each dot value dot prefix is that tier's CIDR, caller-supplied.
   - active: [30, 33]

The subnet block's for_each is the shortest one yet: var dot subnets, straight from input to fan-out. One subnet per key — web, app, data. Each dot key names the subnet — snet dash web and so on — and each dot value is the object from the map, so each dot value dot prefix is that tier's CIDR, caller-supplied.

---

## S010 — FOR_EACH_MAP: The variable's map becomes three keyed subnets

**The variable's map becomes three keyed subnets**

**Steps:**

1. The collection is the variable's map — three entries, each carrying its own prefix and its own nsg flag.
2. for_each expands one block into one instance per key — the addresses are the caller's tier names, not numbers.
3. Names follow keys: snet web, snet app, snet data. Nothing about this fan-out is written in the source — it's all in the tfvars.

The collection is the variable's map — three entries, each carrying its own prefix and its own nsg flag. for_each expands one block into one instance per key — the addresses are the caller's tier names, not numbers. Names follow keys: snet web, snet app, snet data. Nothing about this fan-out is written in the source — it's all in the tfvars.

---

## S011 — CODE

**Steps:**

1. Now the filter. The NSG block's for_each is not the raw variable — it's a for expression over it, with an if at the end: keep k and v only if v dot nsg is true. The condition does the selecting.
   - active: [39]
2. Trace it: web passes — nsg true. App passes. Data fails — nsg false — and drops out of the map entirely. The NSG resource never even sees a data key.
   - active: [39, 40]
3. That's the pattern to remember: the same input feeds two resources, and a filter decides which entries each one acts on. One map, two different fan-outs.
   - active: [38, 39, 40, 41, 42, 43]

Now the filter. The NSG block's for_each is not the raw variable — it's a for expression over it, with an if at the end: keep k and v only if v dot nsg is true. The condition does the selecting. Trace it: web passes — nsg true. App passes. Data fails — nsg false — and drops out of the map entirely. The NSG resource never even sees a data key. That's the pattern to remember: the same input feeds two resources, and a filter decides which entries each one acts on. One map, two different fan-outs.

---

## S012 — FOR_EACH_MAP: The filter: same map, two entries survive

**The filter: same map, two entries survive**

**Steps:**

1. Same map, same three entries — but this time the for expression carries an if clause.
2. The filter evaluates v dot nsg per entry: web and app are true and kept; data is false and dropped.
3. So the NSG fan-out creates exactly two instances — nsg bracket web, nsg bracket app — and data gets no firewall, exactly as the caller declared.

Same map, same three entries — but this time the for expression carries an if clause. The filter evaluates v dot nsg per entry: web and app are true and kept; data is false and dropped. So the NSG fan-out creates exactly two instances — nsg bracket web, nsg bracket app — and data gets no firewall, exactly as the caller declared.

---

## S013 — DIAGRAM: How the pieces connect

**How the pieces connect**

**Steps:**

1. Here's how the pieces connect.
2. The tfvars file supplies the map — caller-owned data.
   - active: ['tfvars']
3. The variable receives it, and the type contract checks every entry.
   - active: ['var']
4. The resource group groups everything in Azure.
   - active: ['rg']
5. The subnets: for_each over the full map — every tier gets a subnet with its own prefix.
   - active: ['subnets']
6. The NSGs: for_each over the FILTERED map — only tiers where nsg is true get a firewall.
   - active: ['nsgs']
7. Everything lands inside your Azure subscription.

Here's how the pieces connect. The tfvars file supplies the map — caller-owned data. The variable receives it, and the type contract checks every entry. The resource group groups everything in Azure. The subnets: for_each over the full map — every tier gets a subnet with its own prefix. The NSGs: for_each over the FILTERED map — only tiers where nsg is true get a firewall. Everything lands inside your Azure subscription.

---

## S014 — TERMINAL

Here's the plan — terraform plan, an illustrative view. The resource group, the VNet, three keyed subnets — app, data, web — and then only TWO NSGs: nsg app and nsg web. No nsg data anywhere, because the filter dropped it. Six to add, zero to destroy.

---

## S015 — CONCEPT: Common pitfall

- A required variable with no default fails plan without a value
- Renaming a key in tfvars destroys and recreates that instance
- The filter lives in code — flipping nsg in tfvars is data-only

**Common pitfall**

Three pitfalls. One: this variable has no default — run plan without a tfvars or dash-var and Terraform stops and asks for the map; that's the type contract doing its job. Two: the keys are identities — rename data to database in the tfvars and Terraform destroys snet data and creates snet database; keys are permanent. Three: notice what's code and what's data — the filter lives in main dot T F, but flipping nsg true on the data tier is a one-line tfvars edit; the next apply simply adds the missing NSG.

---

## S016 — RECAP

- map(object({...})) — a typed variable: every value has a fixed shape
- for_each = var.subnets — the input decides the fan-out
- each.value is the entry's object: .prefix and .nsg
- { for k, v in var.subnets : k => v if v.nsg } — the filtered map
- Same input, two fan-outs: subnets get all keys, NSGs get two

Quick recap — five things. One: map of object gives the variable a strict shape — prefix and nsg on every entry. Two: for_each reads the variable directly, so the caller decides how many subnets exist. Three: each dot value is the entry's object — dot prefix for the CIDR, dot nsg for the flag. Four: a for expression with an if builds the filtered map for the NSGs. Five: one input now feeds two fan-outs — three subnets, two NSGs, and the difference is one boolean per entry. Configuration became data.

---

## S017 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

---

## S018 — CONCEPT: Thanks for watching

**Thanks for watching**

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-02-meta-arguments/33-for-each-variables
```

Thanks for watching. If this helped, the full lab — along with every lab in this course — is in the GitHub repository linked in the description. See you in the next one.

---
