# The Variable Definition File

**Episode:** section-01-foundations/19-variable-definition-file
**Lesson label:** Azure Foundations — Lab 19
**Public lab:** https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies/tree/master/labs/section-01-foundations/19-variable-definition-file
**Scope:** ACTIVE_LAB sources only. No other lab's resources appear.

---

## S001 — TITLE: The Variable Definition File

Lab 18's variables all had defaults. But production configurations usually refuse to guess: variables declared with no default must be supplied — and the standard supplier is a file. This lesson is terraform dot t f vars, the definition file Terraform loads automatically.

## S002 — CONCEPT: What you'll learn

- Variables without defaults are required — Terraform prompts or errors
- terraform.tfvars is auto-loaded by name on every plan/apply
- -var-file selects alternate files (prod.tfvars, staging.tfvars)
- One declaration, many value files — environments without copies

Here's what you'll learn. One: variables without defaults are required — Terraform prompts, or errors. Two: t f vars is auto-loaded by name on every plan and apply. Three: var dash file selects alternate files — prod, staging. Four: one declaration, many value files — environments without copies.

## S003 — CONCEPT: Where this lab fits

- Lab 19 of the Foundations section
- Lab 18 validated the inputs; this lab decides where their values live
- *.auto.tfvars and TF_VAR_/-var exist too — the file is the default source

This is lab nineteen. Last lesson made the inputs strict — validation rejecting bad values. Today's question: where do good values come from? Terraform's answer is a file it loads by convention, plus a flag for everything else.

## S004 — CONCEPT: Auto-loading by name

- terraform.tfvars (and terraform.tfvars.json) loads automatically
- *.auto.tfvars loads too — ordered by filename
- -var-file=prod.tfvars adds any file, on demand
- No default + no value = Terraform prompts interactively (or errors in CI)

The convention is the feature. Name the file terraform dot t f vars, and Terraform loads it on every plan and apply — no flags, no scripts. Any file ending in dot auto dot t f vars loads too. Need a different environment? Keep a prod t f vars and pass var dash file. And if a required variable has no value anywhere, Terraform stops and asks. The declaration stays in code; the values stay in data.

## S005 — CONCEPT: Where to find this lab

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-01-foundations
          └── 19-variable-definition-file
              ├── README.md
              ├── main.tf
              ├── terraform.tf
              ├── variables.tf
              └── terraform.tfvars

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-01-foundations/19-variable-definition-file
```

As always, the lab is in the course GitHub repository under Section 1, Foundations, with the link in the description. Main dot t f declares three variables with no defaults — and terraform dot t f vars is where the values live.

## S006 — CODE: main.tf lines 9-12

Three variables, and notice what's missing: no type keyword beyond the bare minimum, and no defaults anywhere. Location, name prefix, tier — declared and required. Terraform will not invent values for these. The configuration refuses to run until someone supplies them.

## S007 — CODE: main.tf lines 23-36

The consumption is familiar from lab eighteen: the storage account's name assembles the prefix with a random suffix, and the tier flows straight from the variable. The only difference is upstream — nothing here has a fallback. Every value in this block came from outside.

## S008 — CODE: terraform.tfvars lines 1-6

And here's the outside: terraform dot t f vars. Three assignments — one per variable, matching names exactly. No flags needed: Terraform loads this file by name, automatically, on every run. Rename it and it stops loading — the name is the contract.

## S009 — DIAGRAM: The definition file feeds the run

The data flow, drawn out: the definition file is picked up by name, its values land in the required variables, and the resources consume them — no defaults involved anywhere.

## S010 — TERMINAL: terraform apply

Two runs, one configuration. The apply picked up terraform dot t f vars automatically — no flags at all. Then the same code with a different file: var dash file, prod t f vars, and the plan targets a different region, a different prefix, a different tier. Nothing edited. Environments are files, not copies of the code.

## S011 — CONCEPT: Common pitfall — mistaking the example file for the real one

- Only terraform.tfvars auto-loads — terraform.tfvars.example does not
- No default + missing value = an interactive prompt (or a hard error in CI)
- -var-file can be passed multiple times — later files win
- Values on the command line (-var) beat every file

Here are the pitfalls in this lab. One: only terraform dot t f vars auto-loads — the example file does not. The dot example suffix means Terraform ignores it completely; copy it, rename it, and fill it in. Two: no default and a missing value means an interactive prompt — or a hard error in c i. In c i there's no one to answer the prompt, so the missing variable stops the run — which is exactly why the file convention matters. Three: a var file flag can be passed multiple times — later files win. That lets you layer a base file with an environment override. Four: values on the command line beat every file. The var flag has the highest precedence of all.

## S012 — RECAP: recap

- No default = required variable — Terraform prompts or errors
- terraform.tfvars auto-loads by name on every plan/apply
- -var-file swaps in environment files (prod.tfvars)
- Precedence: -var beats -var-file beats auto-loaded files
- Code declares; data supplies — environments are files, not copies

Quick recap — five things. One: no default means a required variable — Terraform prompts, or errors. Two: terraform dot t f vars auto-loads by name on every plan and apply. Three: the var file flag swaps in environment files, like prod dot t f vars. Four: precedence — a var flag beats a var file, which beats auto-loaded files. Five: code declares, data supplies — environments are files, not copies.

## S013 — NEXT: next up

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

## S014 — CONCEPT: Thanks for watching

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-01-foundations/19-variable-definition-file
```

Thanks for watching. If this helped, the full lab, along with every lab in this course, is in the GitHub repository linked below. If you'd like more lessons like this one, give the video a like, share it with a friend who is learning Azure, and subscribe to the channel. It really helps the course grow. Thank you, and see you in the next lesson.
