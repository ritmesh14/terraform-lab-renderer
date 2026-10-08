# Script — Lab 39: Read, Don't Own: Data Sources

*Terraform Meta-arguments — Lab 39. Generated from `source/terraform-inventory.json` + `source/source-manifest.json` (ACTIVE_LAB = `section-02-meta-arguments/39-data-sources`).*

---

## S001 — TITLE: Read, Don't Own: Data Sources

**Read, Don't Own: Data Sources**

Welcome back. Lab 38 gave data sources a cameo. This is Lab 39, and they take the lead role: a data block that READS a resource group that already exists — creates nothing, owns nothing — and then a real resource built INSIDE it, using the discovered attributes. Terraform reading the world before changing it. Let's build it.

---

## S002 — CONCEPT: What you'll learn

- data "azurerm_resource_group" — read an EXISTING group
- Reuse discovered attributes: name, location, tags
- resource vs data: ownership is the whole difference

**What you'll learn**

Three things in this lesson. One: the resource group data block — point it at a name that already exists and Terraform reads its attributes instead of creating anything. Two: putting those discovered attributes to work — a storage account created inside the group, its location and name inherited from the lookup. Three: the distinction that organizes all of Terraform — resource means Terraform owns and manages it; data means Terraform only reads it.

---

## S003 — CONCEPT: Where this lab fits

- Lab 38: data azurerm_client_config — a first, empty-body data source
- This lab: data with a real lookup + attribute reuse
- The pattern scales up: lab 49 fans data sources out with for_each

**Where this lab fits**

Placement. Lab 38 introduced the data keyword with client config — a lookup so simple its body was empty. This lab gives data a body and a target: an existing resource group, found by name from a variable. And the pattern is bigger than this lab — near the end of the section, lab 49 will fan data sources out with for_each. Read today, fan out later.

---

## S004 — CONCEPT: Where to find this lab

**Where to find this lab**

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-02-meta-arguments
          └── 39-data-sources

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-02-meta-arguments/39-data-sources
```

You'll find this lab in the course GitHub repository under Section 2, Meta-arguments — the lab named 39-data-sources. The direct link is in the video description. Main dot T F holds everything; terraform dot T F pins the providers — two of them again.

---

## S005 — CODE

Terraform dot T F first. It pins Terraform 1.5 or newer, and TWO providers this time: azurerm around version 3.70 for Azure, and random around 3.6 — this lab needs a stable random suffix, which we'll see why shortly. The provider block at the bottom bridges to Azure with the standard empty features block.

---

## S006 — CODE

**Steps:**

1. One variable points the data source at its target: existing rg name, defaulting to rg dash already dash here — a group you create once outside Terraform. Change the default to any group your subscription already has.
   - active: [10, 11, 12, 13]

One variable points the data source at its target: existing rg name, defaulting to rg dash already dash here — a group you create once outside Terraform. Change the default to any group your subscription already has.

---

## S007 — CODE

**Steps:**

1. The data block: data azurerm resource group, existing. One argument — the name. That's the entire lookup. Everything else — location, tags, id — comes back as attributes you can reference.
   - active: [16, 17, 18]
2. The comment says it straight: read, do not own. Terraform will never modify or delete this group — even a destroy leaves it untouched, because a data source has nothing to destroy.
   - active: [16]

The data block: data azurerm resource group, existing. One argument — the name. That's the entire lookup. Everything else — location, tags, id — comes back as attributes you can reference. The comment says it straight: read, do not own. Terraform will never modify or delete this group — even a destroy leaves it untouched, because a data source has nothing to destroy.

---

## S008 — CODE

**Steps:**

1. The random string returns from lab 38 — same role, same reason: a stateful suffix so the storage account name is unique but stable across applies.
   - active: [24, 25, 26, 27, 28]

The random string returns from lab 38 — same role, same reason: a stateful suffix so the storage account name is unique but stable across applies.

---

## S009 — CODE

**Steps:**

1. Now the real resource — a storage account — and look where its coordinates come from. Resource group name: data dot azurerm resource group dot existing dot name. Location: the same data source's location. The account is created INSIDE the group Terraform merely read.
   - active: [34, 35]
2. The account name itself: lower of stdata plus the random suffix — lower because storage account names must be lowercase, and Terraform won't silently bend a name that Azure would reject.
   - active: [33]
3. This is the read-then-build pattern: discover what exists, then create new things that fit inside it. The group stays managed elsewhere; the storage account is yours.
   - active: [36, 37]

Now the real resource — a storage account — and look where its coordinates come from. Resource group name: data dot azurerm resource group dot existing dot name. Location: the same data source's location. The account is created INSIDE the group Terraform merely read. The account name itself: lower of stdata plus the random suffix — lower because storage account names must be lowercase, and Terraform won't silently bend a name that Azure would reject. This is the read-then-build pattern: discover what exists, then create new things that fit inside it. The group stays managed elsewhere; the storage account is yours.

---

## S010 — CONCEPT: resource vs data: ownership

- resource: Terraform DECLARES it, creates it, drift-corrects it
- data: Terraform READS it every plan/apply — never changes it
- Data values are known at plan time; wrong names fail the plan

**resource vs data: ownership**

Here's the distinction worth memorizing. A resource block is a declaration of intent: Terraform creates it, records it in state, and corrects drift when reality disagrees. A data block is a lookup: every plan and apply, Terraform re-reads the real thing and hands you its current attributes — and if someone moved that resource group to another region, your next plan sees the new location immediately. One more consequence: data lookups happen at plan time — point at a name that doesn't exist and the plan fails before anything is proposed. A wrong guess is safe to discover.

---

## S011 — DIAGRAM: How the pieces connect

**How the pieces connect**

**Steps:**

1. Here's how the pieces connect.
2. The variable names the target: an existing resource group, rg dash already dash here.
   - active: ['vars']
3. The data block READS that group — location, tags, id come back as attributes. Nothing is created.
   - active: ['data']
4. Random string provides a stable, stateful suffix.
   - active: ['random']
5. The storage account is CREATED — but its group name and location come from the data source, so it lands inside the existing group.
   - active: ['st']
6. Outputs report what was READ: the group's location and tags — known at plan time.
   - active: ['out']
7. Everything lands inside your Azure subscription.

Here's how the pieces connect. The variable names the target: an existing resource group, rg dash already dash here. The data block READS that group — location, tags, id come back as attributes. Nothing is created. Random string provides a stable, stateful suffix. The storage account is CREATED — but its group name and location come from the data source, so it lands inside the existing group. Outputs report what was READ: the group's location and tags — known at plan time. Everything lands inside your Azure subscription.

---

## S012 — TERMINAL

Here's the plan — terraform plan, an illustrative view. Watch the top: data dot azurerm resource group dot existing is being READ — no create marker, no create line. Then two resources to create: the random suffix and the storage account. Two to add, zero to destroy — and notice the existing group appears nowhere in the add list.

---

## S013 — TERMINAL

And the outputs — terraform output, an illustrative view. rg location: eastus — known at plan time, because the group already existed when Terraform looked. rg tags: empty braces here, the group's tags if it had any. Both values were READ, not created.

---

## S014 — CONCEPT: Common pitfall

- A nonexistent name fails at plan time — annoying but safe
- Data re-reads every refresh — external drift shows up in your plan
- Never manage what you read — the ownership boundary is the point

**Common pitfall**

Three pitfalls. One: the plan-time failure is a feature — point at a group that doesn't exist and Terraform stops before creating anything; fix the name and go again. Two: data re-reads on every refresh, so external changes flow into your plan — if someone retags the group, your next plan reflects it; that's correct, but don't let it surprise you. Three: resist the urge to manage what you read — if you start importing the data source's group into resources, you've turned a reader into an owner, and two teams now fight over one group. Read here, create your own things inside.

---

## S015 — RECAP

- data "azurerm_resource_group" reads an existing group by name
- Discovered attributes: .name, .location, .tags — referenced directly
- The storage account is created INSIDE the discovered group
- resource = ownership; data = read-only lookup, every refresh
- Data values are known at plan time — wrong names fail fast

Quick recap — five things. One: the resource group data block reads an existing group by name — a variable supplies the name. Two: its attributes — name, location, tags — are referenced like any resource attribute. Three: the storage account is created inside the discovered group, inheriting its coordinates. Four: the ownership line — resource declares and manages, data only reads. Five: data resolves at plan time, so a wrong name fails before anything happens. Terraform can now read the world before it changes it.

---

## S016 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

---

## S017 — CONCEPT: Thanks for watching

**Thanks for watching**

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-02-meta-arguments/39-data-sources
```

Thanks for watching. If this helped, the full lab — along with every lab in this course — is in the GitHub repository linked in the description. See you in the next one.

---
