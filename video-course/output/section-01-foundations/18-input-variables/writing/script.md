# Input Variables — Types, Defaults, Validation

**Episode:** section-01-foundations/18-input-variables
**Lesson label:** Azure Foundations — Lab 18
**Public lab:** https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies/tree/master/labs/section-01-foundations/18-input-variables
**Scope:** ACTIVE_LAB sources only. No other lab's resources appear.

---

## S001 — TITLE: Input Variables — Types, Defaults, Validation

Variables have appeared in five labs, always briefly. This lesson is their anatomy lesson: type, default, description — and validation blocks that reject impossible values before plan even runs.

## S002 — CONCEPT: What you'll learn

- variable anatomy: type, default, description
- validation blocks run BEFORE plan — bad input never reaches Azure
- can() + regex: shape rules for strings
- contains(): the enum pattern — restrict to allowed values

Here's what you'll learn. One: variable anatomy — type, default, and description. Two: validation blocks run before plan — bad input never reaches Azure. Three: can plus regex — shape rules for strings. Four: contains — the enum pattern that restricts values to an allowed list.

## S003 — CONCEPT: Where this lab fits

- Lab 18 of the Foundations section
- Labs 11 & 17 introduced variables; this lab is the anatomy lesson
- Next lab moves the values out into terraform.tfvars

This is lab eighteen. Variables have been part of five labs now — lab eleven's map of objects, lab seventeen's sensitive password. Today we slow down on the declaration itself: what every variable can carry, and how to make the configuration reject bad input before it ever reaches a plan.

## S004 — CONCEPT: Validation runs before plan

- validation { condition, error_message } — attached to a variable
- can(regex(...)): true if the expression succeeds — a shape gate
- contains(list, value): the enum pattern
- Failures happen locally in seconds — no wasted Azure calls

Here's the idea that makes validation worth writing: it moves failure left. Without it, a bad value travels all the way to Azure and comes back as an error after a plan — or worse, creates something you didn't mean. With a validation block, the same bad value dies locally, in seconds, with a message you wrote. The two workhorse patterns: can plus regex for shape, contains for membership — the poor developer's enum.

## S005 — CONCEPT: Where to find this lab

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-01-foundations
          └── 18-input-variables
              ├── README.md
              ├── main.tf
              ├── terraform.tf
              └── variables.tf

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-01-foundations/18-input-variables
```

As always, the lab is in the course GitHub repository under Section 1, Foundations, with the link in the description. Readme, main dot t f, terraform dot t f — and the variables live in main dot t f this time, next to the logic that consumes them.

## S006 — CODE: main.tf lines 12-16

The simplest variable first, and it shows all three basic fields: type string, default eastus, description Azure region. A defaulted string is already useful — callers can override it, or ignore it entirely.

## S007 — CODE: main.tf lines 20-30

The second variable carries the first validation. Name prefix feeds the storage account's name, so it must obey Azure's lowercase alphanumeric naming — three to eighteen characters. The validation block says exactly that: can of regex, anchored at both ends, with an error message that tells the caller what to fix.

## S008 — CODE: main.tf lines 33-43

The third variable shows the other pattern. Tier should only ever be Standard or Premium — so the validation uses contains: is the value in this list? That's the enum pattern, built from two built-ins. Pass anything else, and Terraform refuses before planning.

## S009 — CODE: main.tf lines 66-73

And the consumption. The storage account's name comes from locals — prefix plus random suffix — and its tier comes straight from the validated variable. By the time this block runs, every value has already passed its gate.

## S010 — DIAGRAM: Validated inputs flow into the build

Drawn out: three validated variables feed the configuration — the region into the resource group, the prefix into the assembled name, the tier into the storage account. Every arrow starts behind a gate that ran before plan.

## S011 — TERMINAL: terraform apply

Two runs tell the story. The apply succeeds with every default in place — three resources. But ask for a tier that isn't on the list, and the validation catches it before plan: invalid value for variable, tier must be Standard or Premium. Seconds, local, with a message you wrote. That's the gate doing its job.

## S012 — CONCEPT: Common pitfall — trusting a default to catch typos

- Defaults are silent: a misspelled region or tier passes straight through
- validation runs before plan — it's your input gate, use it
- error_message should say what to fix, not that something failed
- Validation is for input rules — not for resource behavior

Here are the pitfalls in this lab. One: defaults are silent — a misspelled region or tier passes straight through. A default supplies a value; it can't tell a typo from a choice. Two: validation runs before plan — it's your input gate, so use it. Without it, a bad value sails through plan and fails in Azure — or worse, deploys something you didn't intend. Three: the error message should say what to fix, not just that something failed. A good message names the rule, so bad input dies in seconds on your machine. Four: validation is for input rules — not for resource behavior. It checks what comes in, not what Terraform does with it afterward.

## S013 — RECAP: recap

- variable anatomy: type, default, description
- validation blocks reject bad input before plan
- can(regex(...)) gates the shape; contains(...) gates the choices
- error_message is user-facing documentation — write it for the caller
- Fail locally in seconds, not in Azure after a plan

Quick recap — five things. One: variable anatomy — type, default, description. Two: validation blocks reject bad input before plan. Three: can with regex gates the shape; contains gates the choices. Four: the error message is user-facing documentation — write it for the caller. Five: fail locally in seconds — not in Azure after a plan.

## S014 — NEXT: next up

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

## S015 — CONCEPT: Thanks for watching

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-01-foundations/18-input-variables
```

Thanks for watching. If this helped, the full lab, along with every lab in this course, is in the GitHub repository linked below. If you'd like more lessons like this one, give the video a like, share it with a friend who is learning Azure, and subscribe to the channel. It really helps the course grow. Thank you, and see you in the next lesson.
