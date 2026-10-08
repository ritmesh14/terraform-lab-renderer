# Local Values and Shared Tags

**Episode:** section-01-foundations/07-local-values
**Lesson label:** Azure Foundations — Lab 07
**Public lab:** https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies/tree/master/labs/section-01-foundations/07-local-values
**Scope:** `main.tf` (per source-manifest). No other lab's resources appear.

---

## S001 — TITLE: Local Values and Shared Tags

Locals have been quietly holding our names for six labs. Now we give them their full due: interpolation to build names, and a shared tags map that reaches every resource, with merge for the exceptions.

## S002 — CONCEPT: What you'll learn

- String interpolation inside locals: rg-${local.project}-${local.region}
- A common_tags map defined once, used everywhere
- merge(): common tags + one resource-specific tag
- Why tags matter in real Azure environments

Here's what you'll learn. One: string interpolation inside locals — building the resource group name from project and region. Two: a common tags map, defined once, used everywhere. Three: merge — common tags plus one resource-specific tag. Four: why tags matter in real Azure environments.

## S003 — CONCEPT: Where this lab fits

- Lab 7 of the Foundations section
- Deepens locals from Labs 2–4 into interpolation + maps
- Introduces the merge() function

This is lab seven of the Foundations section. You've used locals since lab two, mostly as simple named values. This lab shows their two biggest real-world jobs: composing names from parts, and holding shared tag maps. Plus one new function: merge.

## S004 — CONCEPT: Why tags, why once

- Tags = key/value labels on every Azure resource
- Used for cost tracking, ownership, automation, cleanup
- Untagged resources are the classic cloud bill surprise
- Define once in locals; merge per-resource extras

A quick word on why tags deserve a whole lab. In real environments, tags are how bills get attributed to teams, how resources get found, and how automation decides what to shut down at night. A resource without tags is a future mystery. So the professional habit is: define your common tags once, and stamp them on everything. Terraform plus locals makes that almost effortless.

## S005 — CONCEPT: Where to find this lab

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-01-foundations
          └── 07-local-values
              ├── README.md
              └── main.tf

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-01-foundations/07-local-values
```

You'll find this lab in the course GitHub repository under Section 1, Foundations, link in the description. One file: main dot T F, a resource group and a virtual network, both wearing the same tags.

## S006 — CODE: main.tf lines 27-30

The locals block starts with two simple values: region and project. Then the interesting line: the resource group name is built by interpolation, project dash region. Read it right to left: change project in one place, and both the resource group and the network name below follow. That's one place naming, doing real work.

## S007 — CODE: main.tf lines 32-39

Here's the star of the lab: common tags, a map defined once in locals. Three pairs: which project, who manages it, and which section of the course it belongs to. In a real company this map grows: environment, cost center, owner. The point isn't the keys, it's the once. Every resource that needs tags points here instead of typing its own copy.

## S008 — CODE: main.tf lines 41-46

The resource group consumes both: name from interpolation, tags straight from the local map, one line. If you've ever met an untagged resource in a subscription with hundreds of them, this single line is the cure.

## S009 — CODE: main.tf lines 48-57

The virtual network shows both tricks together. Its name interpolates the project local again, so vnet dash foundation. And its tags line is the new function: merge takes the common tags map and a small extra map with one key, tier network, and combines them. The result is the shared tags plus one resource-specific label, and the common map itself is untouched.

## S010 — DIAGRAM: One tags map, flowing into every resource

Here's the flow. Common tags lives in locals. It flows directly onto the resource group. For the virtual network, it flows through merge, which adds the tier tag on the way. Change the map once, and both resources update on the next plan. That's the whole point of this lab: shared values live in exactly one place.

## S011 — CODE: main.tf lines 59-60

One output at the end prints the virtual network's final tags, so after apply you can see the merged result with your own eyes: the three common keys, plus tier network.

## S012 — TERMINAL

Apply time. Group first, then the network. And the tags output prints the merged map: project, managed by terraform, section, and the network tier tag. One definition, correct on every resource.

## S013 — CONCEPT: Common pitfall — typing tags on every resource

- Copy-pasted tag maps drift: one resource says terraform, another says iac
- A rename means hunting through every resource block
- merge() exists so shared maps stay shared — extras join at the resource
- Consistent tags are what make cost reports and cleanup scripts possible

Here are the pitfalls in this lab. One: copy-pasted tag maps drift — one resource says terraform, another says i a c. The moment each resource gets its own typed-out map, they start disagreeing. Two: a rename means hunting through every resource block. What should be one edit becomes a search across the whole configuration. Three: merge exists so shared maps stay shared — extras join at the resource. One map in locals, and per-resource extras merged at the point of use. Four: consistent tags are what make cost reports and cleanup scripts possible. If tags drift, your cost dashboard silently misses half the resources.

## S014 — RECAP

- locals build names by interpolation: rg-${project}-${region}
- A shared tags map lives once in locals
- Every resource applies it: tags = local.common_tags
- merge(common_tags, extras) adds per-resource keys without mutating the base
- Outputs print the merged result so you can verify

Quick recap — five things. One: locals build names by interpolation — resource group, project, region. Two: a shared tags map lives once in locals. Three: every resource applies it — tags equals local common tags. Four: merge adds per-resource keys without mutating the base. Five: outputs print the merged result so you can verify.

## S015 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

## S016 — CONCEPT: Thanks for watching

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-01-foundations/07-local-values
```

Thanks for watching. If this helped, the full lab, along with every lab in this course, is in the GitHub repository linked below. If you'd like more lessons like this one, give the video a like, share it with a friend who is learning Azure, and subscribe to the channel. It really helps the course grow. Thank you, and see you in the next lesson.
