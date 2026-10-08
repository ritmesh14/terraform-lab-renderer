# Splitting Config Across Files

**Episode:** section-01-foundations/08-split-config-files
**Lesson label:** Azure Foundations — Lab 08
**Public lab:** https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies/tree/master/labs/section-01-foundations/08-split-config-files
**Scope:** `locals.tf` + `main.tf` + `outputs.tf` + `terraform.tf` (per source-manifest). No other lab's resources appear.

---

## S001 — TITLE: Splitting Config Across Files

Until now, every lab fit in one file. Real projects don't. In this lesson we take the same configuration and split it across four files, and learn the one rule that makes that safe: Terraform merges every dot T F file in the folder into a single configuration.

## S002 — CONCEPT: What you'll learn

- Terraform loads ALL *.tf files in a directory as one config
- The conventional split: terraform.tf, locals.tf, main.tf, outputs.tf
- References work across files with no imports
- File names are for humans — Terraform doesn't care

Here's what you'll learn. One: Terraform loads every dot t f file in a directory as one configuration. Two: the conventional split — terraform dot t f, locals dot t f, main dot t f, outputs dot t f. Three: references work across files with no imports. Four: file names are for humans — Terraform doesn't care.

## S003 — CONCEPT: Where this lab fits

- Lab 8 of the Foundations section
- Same resources as Lab 7 — only the file layout changes
- This is the layout every later lab uses

This is lab eight, and the resources are the same as lab seven: a resource group and a virtual network with shared tags. Nothing about the infrastructure changes. What changes is the organization: four small files instead of one big one. And from here on, this is the layout the course uses.

## S004 — CONCEPT: The merge rule, and the conventional layout

- One rule: every *.tf in the folder merges into one big config
- terraform.tf — version + provider pins
- locals.tf — derived values and shared maps
- main.tf — the resources; outputs.tf — returned values
- There is no import, no include, no order between files

The rule is almost disappointingly simple. When Terraform runs, it reads every dot T F file in the folder and stitches them into one configuration in memory. There is no include statement, no import, and no ordering between files. The conventional layout exists so humans can find things: terraform dot T F for version and provider pins, locals dot T F for derived values, main dot T F for the resources, and outputs dot T F for what comes back. Any team that reads your code later will thank you for following it.

## S005 — CONCEPT: Where to find this lab

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-01-foundations
          └── 08-split-config-files
              ├── README.md
              ├── locals.tf
              ├── main.tf
              ├── outputs.tf
              └── terraform.tf

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-01-foundations/08-split-config-files
```

This lab is in the course GitHub repository under Section 1, Foundations, link in the description. Four files this time, and that's the whole lesson: same infrastructure, better organized.

## S006 — CODE: terraform.tf lines 3-17

File one: terraform dot T F. The version pin and the provider block you've been reading since lab one, now in their own file. Nothing changed semantically. This block just lives here instead of the top of main dot T F.

## S007 — CODE: locals.tf lines 4-12

File two: locals dot T F. The same locals pattern from last lab, interpolated name and common tags, in a file of their own. And here's the key line for this whole lesson: main dot T F will reference these values with no special connection between the files. No import. They're in the same configuration, that's all that matters.

## S008 — CODE: main.tf lines 10-25

File three: main dot T F, now just the resources. Look at the references: local dot rg name, local dot common tags, local dot project. None of those are defined in this file. They come from locals dot T F, and Terraform resolves them as if everything sat together, because effectively it does. The resources themselves are unchanged from lab seven.

## S009 — CODE: outputs.tf lines 3-4

File four: outputs dot T F, with the two outputs you've seen before: the network's I D and its name. Same merge rule applies. An output doesn't need to know which file the virtual network lives in, only its address in the configuration.

## S010 — DIAGRAM: Four files on disk, one config in memory

Here's the mental model. On disk, four files. In memory, one configuration. Terraform merges locals dot T F, main dot T F, outputs dot T F, and terraform dot T F into a single graph, then plans from the graph. That's why references cross file lines for free, and why the names of the files carry zero meaning to Terraform.

## S011 — TERMINAL

The proof is in the run. Four files on disk, but the plan reads like one file: group, network, done. Terraform never mentions the split, because to it, there is no split.

## S012 — CONCEPT: Common pitfall — duplicate declarations across files

- Defining the same local in two files → duplicate definition error
- Two resources with the same address in different files → error too
- The merge rule cuts both ways: split files share one namespace
- Convention: each block type gets one obvious home

Here are the pitfalls in this lab. One: defining the same local in two files is a duplicate definition error. Because all files share one namespace, splitting files changes nothing about uniqueness. Two: two resources with the same address in different files — error too. Even in different files, two resources with the same type and name collide. Three: the merge rule cuts both ways — split files share one namespace. Merging is about organization, not isolation. Four: the convention — each block type gets one obvious home. That's exactly what the conventional layout in this lab demonstrates.

## S013 — RECAP

- Terraform merges every *.tf in the folder into one configuration
- Conventional split: terraform.tf / locals.tf / main.tf / outputs.tf
- References cross files freely — no imports exist in Terraform
- File names are human organization, not Terraform structure
- One namespace still means one definition per name

Quick recap — five things. One: Terraform merges every dot t f file in the folder into one configuration. Two: the conventional split — terraform dot t f, locals dot t f, main dot t f, outputs dot t f. Three: references cross files freely — no imports exist in Terraform. Four: file names are human organization, not Terraform structure. Five: one namespace still means one definition per name.

## S014 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

## S015 — CONCEPT: Thanks for watching

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-01-foundations/08-split-config-files
```

Thanks for watching. If this helped, the full lab, along with every lab in this course, is in the GitHub repository linked below. If you'd like more lessons like this one, give the video a like, share it with a friend who is learning Azure, and subscribe to the channel. It really helps the course grow. Thank you, and see you in the next lesson.
