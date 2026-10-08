# Script — Lab 43: Same VM, Six Files: Restructuring

*Terraform Meta-arguments — Lab 43. Generated from `source/terraform-inventory.json` + `source/source-manifest.json` (ACTIVE_LAB = `section-02-meta-arguments/43-linux-restructure`).*

---

## S001 — TITLE: Same VM, Six Files: Restructuring

**Same VM, Six Files: Restructuring**

Welcome back. Every VM so far lived in one main dot T F. This is Lab 43, and the lab is the SAME virtual machine as last time — same resources, same plan — restructured into six files, grouped by concern. Terraform merges them into one configuration, and that's the lesson: file boundaries are for humans, not for Terraform. Let's look.

---

## S002 — CONCEPT: What you'll learn

- Terraform loads EVERY .tf file in the folder as one configuration
- The standard split: variables / locals / network / vm / outputs
- Cross-file references (vm.tf reading locals.tf) are ordinary

**What you'll learn**

Three things in this lesson. One: the merge rule — every dot T F file in the folder is loaded together as ONE configuration; the file names are purely organizational. Two: the layout serious projects use — inputs in variables dot T F, derived values in locals, network in network dot T F, compute in vm dot T F, outputs in outputs dot T F. Three: references work across files as if nothing moved — vm dot T F reads locals dot T F and network dot T F freely.

---

## S003 — CONCEPT: Where this lab fits

- Lab 42: the same VM in a single main.tf
- This lab: identical resources, restructured files
- The state addresses don't move — type.name is file-independent

**Where this lab fits**

Placement. Lab 42 built this VM in one main dot T F. This lab creates the IDENTICAL resources — only the files change. And because state addresses are type dot name, not file dot name, nothing in the state moves either. The next lab deploys this structure end to end and adds public reachability. And the course modules you'll meet later — the shared network and VM modules — are built exactly this way.

---

## S004 — CONCEPT: Where to find this lab

**Where to find this lab**

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-02-meta-arguments
          └── 43-linux-restructure

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-02-meta-arguments/43-linux-restructure
```

You'll find this lab in the course GitHub repository under Section 2, Meta-arguments — the lab named 43-linux-restructure. The direct link is in the video description. No main dot T F this time — the file tree IS the lesson.

---

## S005 — CODE

Terraform dot T F pins the tooling: Terraform 1.5 or newer, and the azurerm provider around version 3.70 — no extra providers this time. The provider block at the bottom bridges to Azure; the empty features block enables the provider's defaults.

---

## S006 — CODE

**Steps:**

1. variables dot T F: the inputs. One variable — the VM's name, overridable with dash var — defaulting to vm dash structured. Inputs get their own file so a caller can find them instantly.
   - active: [3, 4, 5, 6]

variables dot T F: the inputs. One variable — the VM's name, overridable with dash var — defaulting to vm dash structured. Inputs get their own file so a caller can find them instantly.

---

## S007 — CODE

**Steps:**

1. locals dot T F: derived values. The SSH key ternary moved here unchanged from lab 42 — fileexists guard, file read, fallback.
   - active: [5, 6, 7]
2. And one new derived value: rg, the resource group name. The comment states the rule this lab teaches — Terraform merges every dot T F file into ONE configuration; the names are purely organizational.
   - active: [1, 2, 3, 4, 8, 9]

locals dot T F: derived values. The SSH key ternary moved here unchanged from lab 42 — fileexists guard, file read, fallback. And one new derived value: rg, the resource group name. The comment states the rule this lab teaches — Terraform merges every dot T F file into ONE configuration; the names are purely organizational.

---

## S008 — CODE

**Steps:**

1. network dot T F: grouped by concern. The resource group — its name comes from the locals file, via local dot rg. This reference crosses a file boundary, and it's an ordinary reference.
   - active: [3, 4]
2. The virtual network: vnet dash structure on 10.240 slash 16 — same shape as lab 42, different name and CIDR.
   - active: [10, 11, 14]

network dot T F: grouped by concern. The resource group — its name comes from the locals file, via local dot rg. This reference crosses a file boundary, and it's an ordinary reference. The virtual network: vnet dash structure on 10.240 slash 16 — same shape as lab 42, different name and CIDR.

---

## S009 — CODE

**Steps:**

1. The subnet: snet web, a /24 carved from the VNet's space — still in network dot T F, still the same shape.
   - active: [18, 19, 22]
2. And the NIC — with a comment that matters: it connects the VM declared in vm dot T F to the subnet declared here. Cross-file references are ordinary; the comment makes the split's intent visible.
   - active: [25, 26, 27, 28, 33]

The subnet: snet web, a /24 carved from the VNet's space — still in network dot T F, still the same shape. And the NIC — with a comment that matters: it connects the VM declared in vm dot T F to the subnet declared here. Cross-file references are ordinary; the comment makes the split's intent visible.

---

## S010 — CODE

**Steps:**

1. vm dot T F: the compute block, in its own file so it can be swapped or scaled without touching networking. That's the reason for the split — files group CHANGE, not just code.
   - active: [1, 2, 3, 4]
2. The three cross-file references on display: the name comes from var dot vm name — variables dot T F; the NIC comes from network dot T F; the key comes from local dot ssh pubkey in locals dot T F. Three files, one block.
   - active: [6, 11, 14]
3. And the nested blocks are the lab-42 anatomy, unchanged: os disk, source image — Ubuntu 22.04.
   - active: [16, 20]

vm dot T F: the compute block, in its own file so it can be swapped or scaled without touching networking. That's the reason for the split — files group CHANGE, not just code. The three cross-file references on display: the name comes from var dot vm name — variables dot T F; the NIC comes from network dot T F; the key comes from local dot ssh pubkey in locals dot T F. Three files, one block. And the nested blocks are the lab-42 anatomy, unchanged: os disk, source image — Ubuntu 22.04.

---

## S011 — CODE

**Steps:**

1. outputs dot T F, four lines total: the VM's name and its full Azure resource ID. The id is handy for feeding other systems or tests — and it prints the file-free address: resource group, provider, machine name.
   - active: [3, 4]

outputs dot T F, four lines total: the VM's name and its full Azure resource ID. The id is handy for feeding other systems or tests — and it prints the file-free address: resource group, provider, machine name.

---

## S012 — CONCEPT: The merge rule

- All *.tf files in the folder load as ONE configuration
- File names are organization only — renaming files changes nothing
- Identifiers must still be unique ACROSS files: one variable "vm_name" total

**The merge rule**

Here's the rule the whole lab rests on. Terraform loads every dot T F file in the folder and merges them into a single configuration — the loader doesn't care about file names at all. So you can move blocks between files freely, and rename files freely — nothing in the plan or the state changes. The one constraint: identifiers are unique across the WHOLE configuration, not per file. Two variable vm-name declarations in different files is still an error — as lab 45's comment records. One namespace, many files.

---

## S013 — DIAGRAM: Six files, one configuration

**Six files, one configuration**

**Steps:**

1. Here's how the files connect.
2. variables.tf holds the VM's name input.
   - active: ['vars']
3. locals.tf derives the SSH key and the RG name.
   - active: ['locals']
4. network.tf: resource group, VNet, subnet, NIC — the plumbing.
   - active: ['network']
5. vm.tf: the VM — name from variables, key from locals, NIC from network. Three cross-file references in one block.
   - active: ['vm']
6. outputs.tf reports the name and the full Azure ID.
   - active: ['out']
7. All five files merge into ONE configuration — the folder is the module.

Here's how the files connect. variables.tf holds the VM's name input. locals.tf derives the SSH key and the RG name. network.tf: resource group, VNet, subnet, NIC — the plumbing. vm.tf: the VM — name from variables, key from locals, NIC from network. Three cross-file references in one block. outputs.tf reports the name and the full Azure ID. All five files merge into ONE configuration — the folder is the module.

---

## S014 — TERMINAL

Here's the plan — terraform plan, an illustrative view. Resource group, VNet, subnet, NIC, and the VM named vm dash structured — five to add, zero to destroy. Identical to lab 42's plan in shape: the restructure changed no resources.

---

## S015 — TERMINAL

And the outputs — terraform output, an illustrative view. vm name, and vm id — the full Azure resource ID, the one-liner address of this machine. Note the address carries the resource GROUP and machine name — no file names anywhere in it.

---

## S016 — CONCEPT: Common pitfall

- Every *.tf in the folder loads — a stray scratch.tf breaks the whole config
- File boundaries don't affect state — addresses are type.name, not file paths
- Keep the reference direction sane: compute may read locals, not the reverse

**Common pitfall**

Three pitfalls. One: because every dot T F file loads, a stray scratch file left in the folder joins the configuration — a duplicate identifier there breaks everything. Clean as you go. Two: don't fear the split — file boundaries have zero effect on state or plan; addresses are type dot name. Moving a block between files is safe. Three: with free cross-file references, keep the DIRECTION sane — network and compute read locals and variables; locals and variables read nothing. When references flow both ways between files, the structure is lying about its layers.

---

## S017 — RECAP

- Terraform merges every .tf in the folder into ONE configuration
- The split: variables.tf / locals.tf / network.tf / vm.tf / outputs.tf
- Cross-file references are ordinary — vm.tf reads vars + locals + network
- State addresses are type.name — restructuring moves nothing in state
- Identifiers stay unique ACROSS files: one namespace, many files

Quick recap — five things. One: the folder is the module — every dot T F file merges into one configuration. Two: the standard split — inputs, derived values, network, compute, outputs — one concern per file. Three: cross-file references are ordinary; the VM block reads from three different files. Four: state addresses are type dot name, so restructuring moves nothing. Five: the namespace is still ONE — identifiers must be unique across all files. Same VM as lab 42, but now it's structured the way serious projects are.

---

## S018 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

---

## S019 — CONCEPT: Thanks for watching

**Thanks for watching**

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-02-meta-arguments/43-linux-restructure
```

Thanks for watching. If this helped, the full lab — along with every lab in this course — is in the GitHub repository linked in the description. See you in the next one.

---
