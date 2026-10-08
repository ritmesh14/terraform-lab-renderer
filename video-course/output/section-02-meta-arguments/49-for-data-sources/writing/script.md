# Script — Lab 49: Discovery: for_each over Data Sources

*Terraform Meta-arguments — Lab 49. Generated from `source/terraform-inventory.json` + `source/source-manifest.json` (ACTIVE_LAB = `section-02-meta-arguments/49-for-data-sources`).*

---

## S001 — TITLE: Discovery: for_each over Data Sources

**Discovery: for_each over Data Sources**

Welcome back. Every fan-out so far created resources. This is Lab 49, and the fan-out READS instead: for_each over a data block. Point rg names at resource groups that already exist in your subscription, and Terraform opens one data source per name — read-only, discovering attributes you can feed to real work downstream. The governance pattern: discovery first, bulk action second. Let's look.

---

## S002 — CONCEPT: What you'll learn

- data blocks fan out with for_each — one READ per name
- Read-only: plan shows 0 to add, nothing to destroy
- A wrong name fails at PLAN time — discovery is safe to explore

**What you'll learn**

Three things in this lesson. One: for_each works on data blocks exactly like resources — one data source per key, each reading a resource group that already exists. Two: the footprint — zero; this configuration creates and destroys nothing, and the plan proves it: zero to add, zero to destroy. Three: the safety property — data lookups happen before any change is proposed, so a name that doesn't exist fails the plan immediately, making discovery safe to explore.

---

## S003 — CONCEPT: Where this lab fits

- Labs 28–48: for_each fans out RESOURCES you create
- This lab: for_each fans out READS of what already exists
- The next step in the pattern: feed discovered values to a bulk action

**Where this lab fits**

Placement. Labs 28 through 48 used for_each to create — many VNets, many NICs, many nested blocks. This lab points the same meta-argument at data blocks: reading existing infrastructure instead of writing new. It's the discovery half of the governance pattern — find the groups, then a real bulk action like tagging or locks would consume the discovered values. This lab deliberately stops one step before that.

---

## S004 — CONCEPT: Where to find this lab

**Where to find this lab**

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-02-meta-arguments
          └── 49-for-data-sources

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-02-meta-arguments/49-for-data-sources
```

You'll find this lab in the course GitHub repository under Section 2, Meta-arguments — the lab named 49-for-data-sources. The direct link is in the video description. One short main dot T F — there are no resources in this lab at all, only a variable, locals, data blocks and outputs.

---

## S005 — CODE

No separate terraform dot T F this time — the tooling block is inline at the top of main dot T F: Terraform 1.5 or newer, and the azurerm provider around version 3.70. The provider block below bridges to Azure; the empty features block enables the provider's defaults.

---

## S006 — CODE

**Steps:**

1. The input: rg names, a SET of strings — defaulting to empty. The comments above record two honest facts: the list data source was removed in azurerm 3.x, so discovery is driven by the names you pass in; and an empty set is a no-op — nothing discovered, no data sources created.
   - active: [26, 28, 29]

The input: rg names, a SET of strings — defaulting to empty. The comments above record two honest facts: the list data source was removed in azurerm 3.x, so discovery is driven by the names you pass in; and an empty set is a no-op — nothing discovered, no data sources created.

---

## S007 — CODE

**Steps:**

1. Locals turn the set into a MAP: for each name in rg names, name maps to name. A set would already work for for_each — but an explicit map keeps keys and values visible for beginners, and gives the expression a home to grow into.
   - active: [36, 37, 38]

Locals turn the set into a MAP: for each name in rg names, name maps to name. A set would already work for for_each — but an explicit map keeps keys and values visible for beginners, and gives the expression a home to grow into.

---

## S008 — CODE

**Steps:**

1. The data block — for_each over the map, one read per name. Each instance is addressed data dot azurerm resource group dot each, bracket the name. And the name argument is each dot key — the instance's own key drives what it looks up.
   - active: [42, 43, 44]

The data block — for_each over the map, one read per name. Each instance is addressed data dot azurerm resource group dot each, bracket the name. And the name argument is each dot key — the instance's own key drives what it looks up.

---

## S009 — CODE

**Steps:**

1. Three outputs summarize the discovery: how many groups — length of the map; which ones — the keys; and the ids — a for expression walking the data source map, collecting rg dot id from each instance.
   - active: [49, 50]
2. The ids line is the standard summarizer you'll reuse constantly: for rg in the data map, collect rg dot id. Fan out, then collect — discovery and report in four lines of config.
   - active: [51]

Three outputs summarize the discovery: how many groups — length of the map; which ones — the keys; and the ids — a for expression walking the data source map, collecting rg dot id from each instance. The ids line is the standard summarizer you'll reuse constantly: for rg in the data map, collect rg dot id. Fan out, then collect — discovery and report in four lines of config.

---

## S010 — CONCEPT: The discovery pattern

- data.azurerm_resource_group.each["<name>"] — one instance per key
- Read-only: Terraform plans no changes to discovered groups
- Discovery → bulk action: feed the ids to tagging, locks, or RBAC

**The discovery pattern**

Here's the pattern, named. The data fan-out gives you a map of live Azure objects, addressed by name — data dot azurerm resource group dot each, bracket the name. Terraform plans NO changes to what it reads — data is observation, not management. And the point of collecting the ids: a real governance config would feed them to a bulk action — apply tags to every discovered group, add locks, assign roles. Read, then act — this lab teaches the read half.

---

## S011 — DIAGRAM: How the pieces connect

**How the pieces connect**

**Steps:**

1. Here's how the pieces connect.
2. The input: rg names — a set of names of groups that ALREADY exist.
   - active: ['names']
3. Locals turn the set into the name-to-name map for for_each.
   - active: ['locals']
4. The data blocks fan out — one read per key, each returning the live group's attributes.
   - active: ['data']
5. Outputs summarize: the count, the names, and the collected ids.
   - active: ['out']
6. Nothing is created — this lab only reads and reports.

Here's how the pieces connect. The input: rg names — a set of names of groups that ALREADY exist. Locals turn the set into the name-to-name map for for_each. The data blocks fan out — one read per key, each returning the live group's attributes. Outputs summarize: the count, the names, and the collected ids. Nothing is created — this lab only reads and reports.

---

## S012 — TERMINAL

Here's the plan — terraform plan with two names passed in, an illustrative view. Two data sources to read, marked with the data arrow — and the summary line says everything about this lab: zero to add, zero to change, zero to destroy. Pure discovery.

---

## S013 — TERMINAL

And the output — terraform output discovered rg ids, an illustrative view. One full Azure resource ID per name — exactly the values a bulk action downstream would consume.

---

## S014 — CONCEPT: Common pitfall

- Names must already exist — a wrong name fails at plan time (that's the safety)
- Data re-reads LIVE state every plan/apply — attributes can drift between runs
- This lab creates nothing — there is nothing to destroy, ever

**Common pitfall**

Three pitfalls. One: the names must exist — a typo fails the plan before any change is proposed; that's not a bug, it's the safety property that makes discovery safe. Two: data reads live Azure state on every plan and apply — attributes like tags can drift between runs, so outputs may change without any config change. Three: keep the footprint straight — this lab creates nothing, ever. If you find yourself adding resources here, you've left the discovery pattern behind.

---

## S015 — RECAP

- for_each works on data blocks — one READ instance per key
- data.azurerm_resource_group.each["<name>"] — instances addressed by name
- Read-only: plan shows 0 to add — data observes, it doesn't change
- A wrong name fails at plan time — lookups happen before changes
- [for rg in data... : rg.id] — the standard collect-after-fanout

Quick recap — five things. One: for_each fans out data blocks just like resources — one read per key. Two: instances are addressed by name through the data map. Three: the footprint is zero — read-only, nothing to destroy. Four: a nonexistent name fails at plan time — discovery can't hurt anything. Five: the for expression that collects ids is the summarizer you'll reuse in every governance config. Terraform can now read as well as write.

---

## S016 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

---

## S017 — CONCEPT: Thanks for watching

**Thanks for watching**

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-02-meta-arguments/49-for-data-sources
```

Thanks for watching. If this helped, the full lab — along with every lab in this course — is in the GitHub repository linked in the description. See you in the next one.

---
