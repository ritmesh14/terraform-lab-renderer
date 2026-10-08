# Ordering with depends_on

**Episode:** section-01-foundations/05-depends-on
**Lesson label:** Azure Foundations — Lab 05
**Public lab:** https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies/tree/master/labs/section-01-foundations/05-depends-on
**Scope:** `main.tf` (per source-manifest). No other lab's resources appear.

---

## S001 — TITLE: Ordering with depends_on

Terraform has ordered every resource for you so far, just by following references. But sometimes there is no reference to follow. In this lesson you'll learn when that happens, and how the depends on meta argument forces the order explicitly.

## S002 — CONCEPT: What you'll learn

- Implicit dependency — Terraform infers order from references
- The gap: a plain-string value creates no ordering
- depends_on — forcing order explicitly
- Why a real reference is almost always the better fix

Here's what you'll learn. One: implicit dependency — Terraform infers order from references. Two: the gap — a plain-string value creates no ordering. Three: depends on — forcing order explicitly. Four: why a real reference is almost always the better fix.

## S003 — CONCEPT: Where this lab fits

- Lab 5 of the Foundations section
- Names the rule behind Lab 3's automatic ordering
- Deliberately breaks the reference to show the difference

This is lab five of the Foundations section. Lab three already used implicit dependencies, when the container referenced the storage account's name attribute. This lab deliberately breaks that reference, so you can see exactly what Terraform stops knowing, and how depends on gives the knowledge back.

## S004 — CONCEPT: Two ways Terraform learns about order

- Implicit: A references B's attribute → B is created first
- Explicit: depends_on = [B] inside A → same promise, written by hand
- A plain literal like local.st_name carries no ordering at all
- Terraform parallelizes everything it doesn't see a reason to wait for

Terraform learns about order in exactly two ways. Implicitly: when one resource references another's attribute, the referenced one is built first. Explicitly: when you write depends on. Anything else, like a plain literal from locals, tells Terraform nothing about order. And remember, Terraform parallelizes aggressively. Anything it has no reason to wait for, it won't.

## S005 — CONCEPT: Where to find this lab

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-01-foundations
          └── 05-depends-on
              ├── README.md
              └── main.tf

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-01-foundations/05-depends-on
```

The lab is in the course GitHub repository under Section 1, Foundations, with the link in the description. One file again: main dot T F. The interesting part is at the very bottom, but we'll build up to it in order.

## S006 — CODE: main.tf lines 30-35

The locals block holds the two names. The storage account name combines a prefix with the random suffix and goes through lower, exactly the pattern from labs two and three. Keep an eye on local dot st name. It's about to play two very different roles in this file.

## S007 — CODE: main.tf lines 37-44

The random string is familiar by now: six lowercase characters, saved in state, stable across runs. Nothing new. It feeds the local above it, which feeds the storage account below.

## S008 — CODE: main.tf lines 46-50

The resource group takes its name from locals and a literal region. This is now the third time you've typed this block, which is exactly why later labs will show you how to stop repeating yourself. For now, routine.

## S009 — CODE: main.tf lines 52-60

The storage account gets its name and location from the resource group's attributes. Those two references are the implicit dependency from lab three: Terraform reads them and schedules the group first, automatically. So far, everything in this file orders itself.

## S010 — CODE: main.tf lines 62-71

And here's the lesson. The container needs the storage account's name. But this time we pass the local, the plain string, instead of referencing the account's attribute. Terraform can't tell that this string happens to be an existing resource's name, so it sees no reason to wait, and might create both at once. Depends on closes the gap: it makes the container explicitly wait for the account. Same order as before, but now you had to ask for it.

## S011 — DIAGRAM: What Terraform sees: with and without depends_on

Here's the dependency graph Terraform builds. The solid arrows are references it can see: the group feeds the account. The account also feeds the random suffix, through the local. But the container's link would be invisible, because a local carries no ordering. The dashed arrow is the depends on edge, the one promise you wrote by hand. Remove it, and the container could race the account.

## S012 — TERMINAL

Running it: init pulls the providers, and apply creates the group, then the account, then the container. With depends on in place, the container's turn comes strictly after the account exists, every run, in every pipeline.

## S013 — CONCEPT: Common pitfall — depends_on as a habit

- Lab 3 solved this same problem with a real reference (account's .name)
- depends_on hides WHY the order exists — future readers must guess
- It can also force waits Terraform would have parallelized
- Rule: references first; depends_on only when no reference is possible

Here are the pitfalls in this lab. One: lab three solved this same problem with a real reference — the storage account's name. By referencing the attribute directly, the order came for free, and the code explained itself. Two: depends on hides why the order exists — future readers have to guess. The reason for the dependency is invisible; a reference, by contrast, is self-documenting. Three: it can also force waits that Terraform would have parallelized. Work that has no real dependency gets serialized, and your runs slow down. Four: the rule — references first; depends on only when no reference is possible. Use it when you need ordering against something your config doesn't own.

## S014 — RECAP

- References create implicit dependencies — Terraform orders from them
- A plain literal (local.st_name) carries no ordering information
- depends_on = [resource] forces the wait explicitly
- Prefer real references; keep depends_on for the cases that need it
- Terraform parallelizes everything without a dependency edge

Quick recap — five things. One: references create implicit dependencies — Terraform orders the plan from them. Two: a plain literal, like local st name, carries no ordering information. Three: depends on with a resource forces the wait explicitly. Four: prefer real references — keep depends on for the cases that need it. Five: everything without a dependency edge runs in parallel.

## S015 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

## S016 — CONCEPT: Thanks for watching

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-01-foundations/05-depends-on
```

Thanks for watching. If this helped, the full lab, along with every lab in this course, is in the GitHub repository linked below. If you'd like more lessons like this one, give the video a like, share it with a friend who is learning Azure, and subscribe to the channel. It really helps the course grow. Thank you, and see you in the next lesson.
