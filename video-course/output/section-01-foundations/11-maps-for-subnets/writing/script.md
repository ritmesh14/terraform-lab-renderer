# Typed Map Variables

**Episode:** section-01-foundations/11-maps-for-subnets
**Lesson label:** Azure Foundations — Lab 11
**Public lab:** https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies/tree/master/labs/section-01-foundations/11-maps-for-subnets
**Scope:** ACTIVE_LAB sources only. No other lab's resources appear.

---

## S001 — TITLE: Typed Map Variables

Last lesson the subnet map lived inside locals, and one field, N S G, was sitting unused. In this lesson that exact shape moves into its proper home: a typed input variable, fed by terraform dot t f vars. Same code, different data — the pattern every production Terraform codebase is built on.

## S002 — CONCEPT: What you'll learn

- map(object({...})): a map whose values must match an exact shape
- terraform.tfvars supplies the data — no code edits needed
- for_each over the variable map, same loop as Lab 10
- Outputs that report the layout: length() and keys()

Here's what you'll learn. One: map of object — a map whose values must match an exact shape. Two: t f vars supplies the data — no code edits needed. Three: for each over the variable map — the same loop as lab ten. Four: outputs that report the layout — length, and keys.

## S003 — CONCEPT: Where this lab fits

- Lab 11 of the Foundations section
- Lab 10's locals map becomes a typed input variable
- Data and code split apart: tfvars holds the layout, main.tf holds the logic

This is lab eleven, the assignment lab that follows directly from last lesson. The map of subnets doesn't live in locals anymore: it's now an input variable, and its values come from a separate file. That one move — data out of code — is what turns a teaching example into a reusable pattern.

## S004 — CONCEPT: A type is a contract

- map(object({ prefix = string, nsg = bool })): every value must match exactly
- Wrong field names or wrong types → error before any plan runs
- The .tfvars file is data; the .tf files are logic
- Change the subnet layout by editing data only

A map of object is more than a container: it's a contract. Every key maps to an object with exactly the fields declared here — a prefix string and an N S G boolean. Get the shape wrong, and Terraform rejects the file before any plan runs. That's the point: the code guarantees the data is sane, so the logic below can trust it completely.

## S005 — CONCEPT: Where to find this lab

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-01-foundations
          └── 11-maps-for-subnets
              ├── README.md
              ├── main.tf
              ├── outputs.tf
              ├── terraform.tf
              └── terraform.tfvars

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-01-foundations/11-maps-for-subnets
```

As always, the lab is in the course GitHub repository under Section 1, Foundations, with the link in the description. Main dot t f, outputs dot t f, terraform dot t f, and — new since lab two — terraform dot t f vars, the data file this lesson is really about.

## S006 — CODE: main.tf lines 9-24

First the variable itself. Location is a plain string with a default. Subnets is the interesting one: a map of object, where every value must carry a prefix and an N S G flag. And notice — there's no default. The code refuses to guess a network layout. The data has to come from outside.

## S007 — CODE: terraform.tfvars lines 1-7

And here's the outside: terraform dot t f vars. Three keys — web, app, data — each an object with a prefix and an N S G flag, exactly the shape the variable demanded. Want a different layout for another environment? Edit this file and nothing else. Data changed, code untouched.

## S008 — CODE: main.tf lines 26-47

The resources are almost identical to last lesson. A resource group, a VNet, and one subnet resource with for each over the variable. Inside, each dot key names the subnet — s n e t, then the role — and each dot value dot prefix sets its address. The only thing that changed is where the map comes from.

## S009 — DIAGRAM: One variable, one layout — data drives the build

Here's what the split looks like drawn out. The data file feeds a typed variable, and for each turns it into three subnets named after their roles. Edit the data, and the plan reshapes itself. The code never moves.

## S010 — CODE: outputs.tf lines 1-4

Two small outputs report the layout. Length counts the map entries, so subnet count is simply three. And keys lists the for each keys that became subnets — a quick, readable answer to the question, what did this configuration actually build?

## S011 — TERMINAL: terraform apply

Apply time. Five resources — group, VNet, and three subnets — all from one block plus one data file. The outputs confirm the shape: three entries, and the keys are the roles. Change the t f vars file and the next plan reshapes itself; the code stays exactly as it is.

## S012 — CONCEPT: Common pitfall — treating the type as loose guidance

- tfvars must match map(object(...)) exactly — misspelled or missing fields are hard errors
- The rejection happens before any plan — fail fast, by design
- Keeping an unused field (nsg) in the shape is normal while a module grows
- Adding a field later breaks every caller — design the shape up front

Here are the pitfalls in this lab. One: t f vars must match the map of object type exactly — misspelled or missing fields are hard errors. The type is a contract, not loose guidance; Terraform refuses the whole file before planning anything. Two: the rejection happens before any plan — fail fast, by design. A string where a boolean belongs dies in seconds on your machine instead of in the cloud. Three: keeping an unused field in the shape is normal while a module grows. The n s g flag is still riding along unused — that's deliberate. Four: adding a field later breaks every caller — design the shape up front. Add fields when you design, not when you deploy.

## S013 — RECAP: recap

- map(object({...})) is a shape-checked container — a contract, not a hint
- terraform.tfvars supplies the data; main.tf holds the logic
- for_each = var.subnets: same loop, data-driven source
- length() and keys() report the built layout
- Same code, different shapes per environment

Quick recap — five things. One: map of object is a shape-checked container — a contract, not a hint. Two: terraform dot t f vars supplies the data; main dot t f holds the logic. Three: for each over var dot subnets — the same loop, with a data-driven source. Four: length and keys report the built layout. Five: same code, different shapes per environment.

## S014 — NEXT: next up

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

## S015 — CONCEPT: Thanks for watching

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-01-foundations/11-maps-for-subnets
```

Thanks for watching. If this helped, the full lab, along with every lab in this course, is in the GitHub repository linked below. If you'd like more lessons like this one, give the video a like, share it with a friend who is learning Azure, and subscribe to the channel. It really helps the course grow. Thank you, and see you in the next lesson.
