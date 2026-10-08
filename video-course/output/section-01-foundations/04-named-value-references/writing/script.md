# Named Value References

**Episode:** section-01-foundations/04-named-value-references
**Lesson label:** Azure Foundations — Lab 04
**Public lab:** https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies/tree/master/labs/section-01-foundations/04-named-value-references
**Scope:** `main.tf` (per source-manifest). No other lab's resources appear.

---

## S001 — TITLE: Named Value References

You've been reading references like local dot name and var dot location for three labs now. In this lesson we slow down and make them official: the three reference families every Terraform file uses. Master these, and you'll never hardcode the same value twice.

## S002 — CONCEPT: What you'll learn

- The three reference families: local.x, var.x, resource references
- Input variables with defaults — and how to override them
- Chaining functions: md5 + substr to build a name from a resource ID
- Why references are better than repeating literals

Here's what you'll learn. One: the three reference families — local dot x, var dot x, and resource references. Two: input variables with defaults — and how to override them. Three: chaining functions — m d five plus substr, building a name from a resource I D. Four: why references are better than repeating literals.

## S003 — CONCEPT: Where this lab fits

- Lab 4 of the Foundations section
- Names a pattern you've been using since Lab 1
- Variables appear officially for the first time

This is lab four of the Foundations section. The references themselves aren't new: labs one through three used local references and resource references already. What's new is the input variable, which gets a proper introduction here, and the habit of deliberately choosing the right family for each value.

## S004 — CONCEPT: Three ways to name a value

- local.<name> — a value computed inside this configuration
- var.<name> — an input from outside, with a default
- azurerm_<type>.<name>.<attr> — a value produced by a resource
- Each family answers: who owns this value?

So, three families. A local is a value this configuration computes and owns. A variable is a value the caller provides, with a default as a fallback. And a resource reference is a value Azure or Terraform produced when the resource was created. The way to choose is to ask one question: who owns this value? The answer tells you which family to use.

## S005 — CONCEPT: Where to find this lab

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-01-foundations
          └── 04-named-value-references
              ├── README.md
              ├── main.tf
              └── variables.tf

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-01-foundations/04-named-value-references
```

You'll find this lab in the course GitHub repository under Section 1, Foundations — link in the description. Two files this time: main dot T F, and variables dot T F, which is deliberately empty and we'll talk about why.

## S006 — CODE: main.tf lines 30-32

The locals block first, because it's the simplest family. One value: the resource group name. Once it's defined here, every place that needs it says local dot rg name. One definition, many uses. If we ever rename the group, we change exactly one line.

## S007 — CODE: main.tf lines 34-38

Now the second family: an input variable. It has a type, string, and a default value, east us. Because of the default, running apply with no extra input just works. But anyone using this configuration can pass a different region with a var flag or a TF vars file, without touching the code. That's the difference from a local: a local belongs to the config, a variable belongs to the caller.

## S008 — CODE: main.tf lines 40-44

The resource group uses both families side by side. The name comes from a local, the location from the variable. Two lines, two different decisions: the name is ours to compute, the region is someone's choice at deploy time. Reading a block like this, you always know where each value came from.

## S009 — CODE: main.tf lines 46-54

The storage account shows the third family, plus a function chain. The name is built from a prefix, then a hash of the resource group's I D, trimmed to six characters and lowercased. Same globally-unique-name rule as before, but notice: no random resource needed this time. The hash of the group I D is already stable. And the name and location references, just like last lab, order the plan.

## S010 — DIAGRAM: Every value in this lab, and where it comes from

Here's the full picture of value flow. The location variable feeds the resource group. The local name feeds it too. The group's I D feeds the hash that names the storage account. And the group's name and location flow into the account directly. Nothing is written twice, and every arrow starts at the value's true owner.

## S011 — CODE: main.tf lines 56-59

Two outputs close the file, and they're references too: the resource group's name, and the computed storage account name. Outputs were your first taste of references back in lab one. After apply, these two lines print the proof that the whole chain resolved.

## S012 — TERMINAL

Let's run it. With no variables passed, the default east us applies, and Terraform creates the group and the storage account. Then the outputs print both names, including the hash suffix built from the group's I D. And if you re-run with a different region flag, only the location changes. The code stays untouched.

## S013 — CONCEPT: Common pitfall — hardcoding instead of referencing

- Writing "rg-refs-foundation" twice = two places to drift apart
- Hardcoded location strings make region changes a find-and-replace hunt
- Rule: a literal may appear once; everything else is a reference
- variables.tf is empty here on purpose — location stays beside the examples

Here are the pitfalls in this lab. One: writing the resource group name twice means two places to drift apart. If a literal appears in two places, those two places can disagree, and Terraform will happily create two groups. Two: hard-coded location strings turn a region change into a find and replace hunt. The same drift risk applies to region strings scattered across the file. Three: the rule — a literal may appear once; everything else is a reference. Define each value at its owner, and reference it everywhere else. Four: variables dot t f is empty here on purpose — location stays beside the examples. The variable lives in main dot t f in this lab so it sits next to the teaching examples; in real projects, variables get their own file.

## S014 — RECAP

- local.<name> — values this configuration computes and owns
- var.<name> — caller input, with a default; override via -var or tfvars
- Resource references feed values between resources and order the plan
- md5 + substr built a stable unique suffix from a resource ID
- One literal at the owner; every other use is a reference

Quick recap — five things. One: local dot name — values this configuration computes and owns. Two: var dot name — caller input with a default, overridable with a var flag or t f vars. Three: resource references feed values between resources and order the plan. Four: m d five plus substr built a stable unique suffix from a resource i d. Five: one literal at the owner — every other use is a reference.

## S015 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

## S016 — CONCEPT: Thanks for watching

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-01-foundations/04-named-value-references
```

Thanks for watching. If this helped, the full lab, along with every lab in this course, is in the GitHub repository linked below. If you'd like more lessons like this one, give the video a like, share it with a friend who is learning Azure, and subscribe to the channel. It really helps the course grow. Thank you, and see you in the next lesson.
