# Script — Lab 28: Names That Mean Something: for_each over a Set

*Terraform Meta-arguments — Lab 28. Generated from `source/terraform-inventory.json` + `source/source-manifest.json` (ACTIVE_LAB = `section-02-meta-arguments/28-for-each-meta-argument`).*

---

## S001 — TITLE: Names That Mean Something: for_each over a Set

**Names That Mean Something: for_each over a Set**

Welcome back to the course. Count made copies — but numbered ones: data zero, data one, data two. This is Lab 28, and we meet for_each: copies that carry a meaningful name instead of a number. One block, a set of keys — dev, stg, prod — and every copy is addressed by the name you chose. Let's build it.

---

## S002 — CONCEPT: What you'll learn

- for_each creates one copy per collection key
- toset() turns a list into the set for_each needs
- each.value — and addressing a copy by its key

**What you'll learn**

Here's what you'll learn in this lesson — three things. One: for_each is the second fan-out meta-argument — it creates one resource instance per element of a collection, and each instance is addressed by its key, not by a number. Two: toset, the function that turns a plain list into the set for_each expects. Three: each dot value — how one block reads the current key as it expands — and how you address any single copy by name later.

---

## S003 — CONCEPT: Where this lab fits

- Labs 26–27: count — copies addressed by position [0], [1], [2]
- This lab: for_each — copies addressed by name
- The next labs feed for_each richer collections: maps

**Where this lab fits**

This is the third lab of Section 2, Meta-arguments. Labs 26 and 27 used count: the copies came out as a numbered list — data in brackets zero, one, two — and an address was a position. This lab swaps the counter for names: the same one-block idea, but every instance is addressed by a meaningful key. And the labs after this one feed for_each richer collections — maps where each entry carries its own configuration.

---

## S004 — CONCEPT: Where to find this lab

**Where to find this lab**

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-02-meta-arguments
          └── 28-for-each-meta-argument
              ├── README.md
              ├── main.tf
              └── terraform.tf

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-02-meta-arguments/28-for-each-meta-argument
```

You can find this lab in the course GitHub repository under Section 2, Meta-arguments — the lab named 28-for-each-meta-argument. The direct link is in the video description. Two files matter in this lesson: main dot T F holds the whole configuration, and terraform dot T F pins the providers.

---

## S005 — CONCEPT: The mental model: name badges, not seat numbers

- count prints seat numbers: [0], [1], [2]
- for_each prints name badges: ["dev"], ["stg"], ["prod"]
- A badge says what the thing is for — a number doesn't

**The mental model: name badges, not seat numbers**

Before any code, here's the mental model. Count puts your copies in numbered seats: row zero, row one, row two. for_each hands out name badges instead: dev, stg, prod. A seat number tells you where something sits — but only until the seating changes. A name badge tells you what the thing is for, and it stays true no matter how the collection grows or shrinks. That difference is the whole point of this lab.

---

## S006 — CODE

The configuration lives in two files. Terraform dot T F pins the tooling: Terraform 1.5 or newer, the azurerm provider around version 3.70, and the random provider — this lab uses it for a unique suffix. The provider block at the bottom is the bridge to Azure; the empty features block enables the provider's default behaviours. Nothing new here — the interesting code is in main dot T F.

---

## S007 — CODE

**Steps:**

1. The fan-out collection sits in locals. Stages is the result of toset — to set of dev, stg, prod. toset takes a plain list and returns a set: unique elements, no order, exactly the shape for_each wants.
   - active: [7, 8, 9, 10]
2. The second local computes the storage account name — lowercase, with a random suffix appended. Locals hold values written once and reused everywhere below.
   - active: [11]

The fan-out collection sits in locals. Stages is the result of toset — to set of dev, stg, prod. toset takes a plain list and returns a set: unique elements, no order, exactly the shape for_each wants. The second local computes the storage account name — lowercase, with a random suffix appended. Locals hold values written once and reused everywhere below.

---

## S008 — CODE

**Steps:**

1. The suffix comes from random_string: six lowercase characters, no specials. It's a resource, not a function — so the value it generates is saved in Terraform state.
   - active: [17, 18, 19, 20, 21]
2. That stateful design matters: because the value lives in state, every future plan and apply keeps the same suffix. Names stay stable between runs — nothing gets unexpectedly replaced.
   - active: [17, 18, 19, 20, 21]

The suffix comes from random_string: six lowercase characters, no specials. It's a resource, not a function — so the value it generates is saved in Terraform state. That stateful design matters: because the value lives in state, every future plan and apply keeps the same suffix. Names stay stable between runs — nothing gets unexpectedly replaced.

---

## S009 — CODE

**Steps:**

1. The resource group gets a fixed name — rg dash foreach dash meta.
   - active: [24, 25, 26, 27]
2. The storage account references the group for its name and location — that reference is an implicit dependency, so the group is always created first. Its own name comes from the locals block, random suffix baked in.
   - active: [31, 32, 33, 34, 35, 36, 37]

The resource group gets a fixed name — rg dash foreach dash meta. The storage account references the group for its name and location — that reference is an implicit dependency, so the group is always created first. Its own name comes from the locals block, random suffix baked in.

---

## S010 — CODE

**Steps:**

1. And here is the star of the lab. It's one ordinary container block — no count anywhere. Instead, for_each reads the locals set: for_each equals local dot stages. One block, three keys — Terraform does the rest.
   - active: [41, 42]
2. Inside the block, each dot value is the current element of the set. As the block expands, each copy sees one key: this copy's name is each dot value — dev for one, stg for the next, prod for the last.
   - active: [43]
3. Each copy also references the storage account for its parent — every instance waits for the account, and they're all private containers.
   - active: [44, 45]

And here is the star of the lab. It's one ordinary container block — no count anywhere. Instead, for_each reads the locals set: for_each equals local dot stages. One block, three keys — Terraform does the rest. Inside the block, each dot value is the current element of the set. As the block expands, each copy sees one key: this copy's name is each dot value — dev for one, stg for the next, prod for the last. Each copy also references the storage account for its parent — every instance waits for the account, and they're all private containers.

---

## S011 — FOR_EACH_MAP: One set, one block, three named copies

**One set, one block, three named copies**

**Steps:**

1. The collection is a set — three unique strings. Order doesn't matter and duplicates can't exist; the keys are the names themselves.
2. for_each walks the set and expands the one block into one instance per key — three containers, created from a single resource block.
3. With a set, each dot key and each dot value are the same string — so copy's name is simply each dot value: dev, stg, prod.
4. And look at the addresses in state: stage in brackets, quote, dev, quote. The key IS the address — readable, meaningful, and stable. No positions anywhere.

The collection is a set — three unique strings. Order doesn't matter and duplicates can't exist; the keys are the names themselves. for_each walks the set and expands the one block into one instance per key — three containers, created from a single resource block. With a set, each dot key and each dot value are the same string — so copy's name is simply each dot value: dev, stg, prod. And look at the addresses in state: stage in brackets, quote, dev, quote. The key IS the address — readable, meaningful, and stable. No positions anywhere.

---

## S012 — CODE

**Steps:**

1. The output reads the copies back. A for_each resource is a MAP of instances — keyed by those same strings — so keys of the resource returns the key list: dev, stg, prod.
   - active: [51]
2. And because instances are keyed, you can address one directly: azurerm_storage_container dot stage, bracket, quote dev quote — that single expression is one specific container, no index hunting.
   - active: [51]

The output reads the copies back. A for_each resource is a MAP of instances — keyed by those same strings — so keys of the resource returns the key list: dev, stg, prod. And because instances are keyed, you can address one directly: azurerm_storage_container dot stage, bracket, quote dev quote — that single expression is one specific container, no index hunting.

---

## S013 — CONCEPT: count or for_each?

- count — numbered copies, positional addresses [0], [1], [2]
- for_each — named copies, keyed addresses ["dev"]
- Copies differ, or names matter? Reach for for_each

**count or for_each?**

So which one do you reach for? Count is the right tool when the copies are truly identical and position is fine — think identical workers lined up in a row. for_each is the right tool when the copies differ in meaning, or when a stable, readable name matters more than a number. The lab's own comment says it plainly: prefer for_each over count when copies differ in config and are best addressed by a meaningful key. And the next labs make that concrete — for_each over maps, where every entry carries its own configuration.

---

## S014 — DIAGRAM: How the pieces connect

**How the pieces connect**

**Steps:**

1. Here's how the pieces connect.
2. Locals hold the set of stage names and the account name.
   - active: ['locals']
3. The random string generates the suffix and saves it in state.
   - active: ['random']
4. Locals take that suffix and compute the account's name.
   - active: ['locals']
5. The resource group groups everything in Azure.
   - active: ['rg']
6. The storage account references the group — group first, account second — with its name from locals.
   - active: ['st']
7. And the containers: for_each walks the set, so one block fans out into dev, stg and prod — each inside the account.
   - active: ['containers']
8. The output lists the keys back — the three stage names.
   - active: ['out']
9. Everything lands inside your Azure subscription.

Here's how the pieces connect. Locals hold the set of stage names and the account name. The random string generates the suffix and saves it in state. Locals take that suffix and compute the account's name. The resource group groups everything in Azure. The storage account references the group — group first, account second — with its name from locals. And the containers: for_each walks the set, so one block fans out into dev, stg and prod — each inside the account. The output lists the keys back — the three stage names. Everything lands inside your Azure subscription.

---

## S015 — TERMINAL

Here's the plan — terraform plan, an illustrative view. Count the entries: the random string, the resource group, the storage account, and three containers — stage in brackets dev, stage in brackets prod, stage in brackets stg. Six to add, zero to destroy. One block in the code; three named copies in the plan.

---

## S016 — TERMINAL

And here's the proof in state — terraform state list, an illustrative view. The container addresses are the keys themselves: stage in brackets dev, brackets prod, brackets stg. Compare that with count's data zero, data one, data two. These addresses read like the infrastructure they point at — and they don't shift when the collection changes.

---

## S017 — CONCEPT: Common pitfall

- toset() dedupes silently — duplicate strings collapse
- A set's elements must be strings — richer config needs a map
- The key IS the identity — renaming a key destroys and recreates

**Common pitfall**

One pitfall to understand before you reach for for_each everywhere. One: toset removes duplicates silently — feed it a list with dev twice, and you get one dev, no warning. Two: a set's elements are plain strings — the moment each copy needs its own settings, a set isn't enough; that's what maps are for, and the next labs show them. And three, the big one: the key is the instance's identity. Rename dev to staging in the set, and Terraform doesn't rename anything — it destroys the dev container and creates a staging one. Keys are addresses; treat them as permanent.

---

## S018 — RECAP

- for_each = local.stages — one copy per set element
- toset() turns a list into the set for_each expects
- each.value is the current key — with a set, key equals value
- Addresses are the keys: stage["dev"], not stage[0]
- keys() on the resource lists every key back

Quick recap — five things. One: for_each equals local dot stages — one copy per element of the set. Two: toset turned a plain list into that set — unique, unordered. Three: each dot value is the current key as the block expands — with a set, key and value are the same. Four: the state addresses are the keys themselves — stage bracket dev — readable and stable, no positions. Five: keys on the resource lists every key back. One block — and the copies have names that mean something.

---

## S019 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

---

## S020 — CONCEPT: Thanks for watching

**Thanks for watching**

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-02-meta-arguments/28-for-each-meta-argument
```

Thanks for watching. If this helped, the full lab — along with every lab in this course — is in the GitHub repository linked in the description. See you in the next one.

---
