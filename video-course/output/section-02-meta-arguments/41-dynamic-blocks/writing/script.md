# Script — Lab 41: One Block, Many Rules: Dynamic Blocks

*Terraform Meta-arguments — Lab 41. Generated from `source/terraform-inventory.json` + `source/source-manifest.json` (ACTIVE_LAB = `section-02-meta-arguments/41-dynamic-blocks`).*

---

## S001 — TITLE: One Block, Many Rules: Dynamic Blocks

**One Block, Many Rules: Dynamic Blocks**

Welcome back. Labs 28 through 37 fanned out whole RESOURCES. This is Lab 41, and we go one level deeper: fanning out NESTED BLOCKS inside a single resource. One NSG, whose security rules are stamped out by a dynamic block from a plain variable list. Add a rule to the input and the firewall extends — no code changes. Let's build it.

---

## S002 — CONCEPT: What you'll learn

- dynamic "security_rule" { for_each = var.rules } — nested blocks from data
- security_rule.value — addressing the current element inside content
- Add a rule to tfvars → the NSG extends with no code changes

**What you'll learn**

Three things in this lesson. One: the dynamic block itself — you write the block ONCE, and its for_each generates one nested block per element of a variable list. Two: the addressing inside — the block's label dot value is the current list element, so name, priority and port all come from data. Three: the payoff — this config's rule count is decided by the CALLER. Add a rule to tfvars and apply, and the NSG grows without touching main dot T F.

---

## S003 — CONCEPT: Where this lab fits

- Labs 28–37: fan-outs over whole RESOURCES (for_each / count)
- This lab: fan-out INSIDE one resource — repeated nested blocks
- The last fan-out shape: data decides the resource's own anatomy

**Where this lab fits**

Placement. The meta-argument stretch so far fanned out whole resources — many subnets, many NICs, many VMs. Dynamic blocks go one level deeper: ONE resource whose internal anatomy is itself repeated — one NSG, many security rules, generated from data. You've seen the static version already: lab 34 wrote one security_rule block per tier BY HAND. Dynamic makes that list caller-owned.

---

## S004 — CONCEPT: Where to find this lab

**Where to find this lab**

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-02-meta-arguments
          └── 41-dynamic-blocks

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-02-meta-arguments/41-dynamic-blocks
```

You'll find this lab in the course GitHub repository under Section 2, Meta-arguments — the lab named 41-dynamic-blocks. The direct link is in the video description. Main dot T F holds everything; terraform dot T F pins the providers.

---

## S005 — CODE

Terraform dot T F pins the tooling: Terraform 1.5 or newer, and the azurerm provider around version 3.70 — no extra providers this time. The provider block at the bottom bridges to Azure; the empty features block enables the provider's defaults.

---

## S006 — CODE

**Steps:**

1. The input is a LIST of objects — the type contract says every rule must carry a name, a priority, and a port. Three strings and numbers, checked by Terraform before anything runs.
   - active: [11, 12, 13, 14, 15]
2. And the default ships two rules: Allow HTTP on port 80 with priority 200, and Allow HTTPS on 443 with priority 210. Two entries — so two nested blocks will be generated.
   - active: [16, 17, 18, 19]

The input is a LIST of objects — the type contract says every rule must carry a name, a priority, and a port. Three strings and numbers, checked by Terraform before anything runs. And the default ships two rules: Allow HTTP on port 80 with priority 200, and Allow HTTPS on 443 with priority 210. Two entries — so two nested blocks will be generated.

---

## S007 — CODE

**Steps:**

1. The resource group — rg dash dynamic. The container for everything this lab creates.
   - active: [23, 24, 25, 26]

The resource group — rg dash dynamic. The container for everything this lab creates.

---

## S008 — CODE

**Steps:**

1. The NSG block itself looks ordinary at the top: nsg dash dynamic, location and group from the resource group. The unusual part comes next — there is NOT a single hard-coded security_rule block in this resource.
   - active: [31, 32, 33, 34]

The NSG block itself looks ordinary at the top: nsg dash dynamic, location and group from the resource group. The unusual part comes next — there is NOT a single hard-coded security_rule block in this resource.

---

## S009 — DYNAMIC_BLOCK: dynamic "security_rule" — nested blocks from a variable

**dynamic "security_rule" — nested blocks from a variable**

**Steps:**

1. The dynamic block declares the LABEL — security_rule — and drives it with for_each over the rules variable.
2. For each element, the content block runs once, and security_rule dot value IS that element: value dot name, value dot priority, value dot port.
3. The result: two real security_rule blocks inside one NSG — generated, not hand-written. The plan output shows both, exactly as if you'd typed them.

The dynamic block declares the LABEL — security_rule — and drives it with for_each over the rules variable. For each element, the content block runs once, and security_rule dot value IS that element: value dot name, value dot priority, value dot port. The result: two real security_rule blocks inside one NSG — generated, not hand-written. The plan output shows both, exactly as if you'd typed them.

---

## S010 — CODE

**Steps:**

1. Inside content, the block's own fields are bound from the element: name equals security_rule dot value dot name; priority from value dot priority. The nested block is a template; each element fills it in.
   - active: [39, 40]
2. Direction, access, protocol are constants here; the destination port is data again: tostring of security rule dot value dot port. tostring, because the port is a number and the argument is a string — the conversion you met in lab 34.
   - active: [41, 42, 43, 44, 45, 46, 47]

Inside content, the block's own fields are bound from the element: name equals security_rule dot value dot name; priority from value dot priority. The nested block is a template; each element fills it in. Direction, access, protocol are constants here; the destination port is data again: tostring of security rule dot value dot port. tostring, because the port is a number and the argument is a string — the conversion you met in lab 34.

---

## S011 — CODE

**Steps:**

1. The output uses a for expression to collect just the names from the rules variable — one name per dynamic block that will be generated. Proof that the list, not the config, decides what exists.
   - active: [54, 55, 56]

The output uses a for expression to collect just the names from the rules variable — one name per dynamic block that will be generated. Proof that the list, not the config, decides what exists.

---

## S012 — DIAGRAM: How the pieces connect

**How the pieces connect**

**Steps:**

1. Here's how the pieces connect.
2. The variables block holds the rules list — two rules by default.
   - active: ['vars']
3. The resource group groups everything in Azure.
   - active: ['rg']
4. The NSG: ONE resource, whose security_rule blocks are generated by the dynamic block from that list.
   - active: ['nsg']
5. The output collects the rule names — one per generated block, straight from the list.
   - active: ['out']
6. Everything lands inside your Azure subscription.

Here's how the pieces connect. The variables block holds the rules list — two rules by default. The resource group groups everything in Azure. The NSG: ONE resource, whose security_rule blocks are generated by the dynamic block from that list. The output collects the rule names — one per generated block, straight from the list. Everything lands inside your Azure subscription.

---

## S013 — TERMINAL

Here's the plan — terraform plan, an illustrative view. Two resources to add: the resource group and the NSG. Look inside the NSG: two security_rule blocks, generated by the dynamic block — Allow HTTP and Allow HTTPS, priorities 200 and 210. One resource in the add list, two nested blocks inside it.

---

## S014 — TERMINAL

And the output — terraform output rule_names, an illustrative view. Two names, straight from the list: Allow HTTP, Allow HTTPS. Add a third rule to tfvars and this list — and the NSG — grow together on the next apply.

---

## S015 — CONCEPT: Common pitfall

- dynamic fans out NESTED BLOCKS — resources are for_each/count's job
- Inside content the label scopes addressing: security_rule.value, not each.value
- Numbers into string arguments need tostring() — port is a number

**Common pitfall**

Three pitfalls. One: dynamic is for nested blocks INSIDE a resource — for whole extra resources, for_each on the resource itself is still the tool; mixing them up is a common beginner detour. Two: inside content, addressing goes through the BLOCK label — security_rule dot value here — not each dot value; the label scopes the iteration. Three: the port is a number, the argument is a string — tostring makes the conversion explicit; Terraform refuses to guess types silently.

---

## S016 — RECAP

- dynamic "security_rule" { for_each = var.rules } — one block, many copies
- content { ... } binds each element: security_rule.value.name / .priority / .port
- tostring(each.value.port) — explicit number-to-string conversion
- Rule count is caller-owned: add to tfvars, apply, the NSG extends
- Lab 34's hand-written rules vs lab 41's generated ones — same result, data-driven

Quick recap — five things. One: a dynamic block generates repeated nested blocks from a collection — one block, many copies. Two: content is the template, and security rule dot value binds each element's fields. Three: tostring converts the numeric port for a string argument. Four: the rule count is caller-owned — tfvars can extend the NSG with no code changes. Five: same result as lab 34's hand-written rules, but now the data drives the anatomy. That's the last fan-out shape — resources, addresses, and now nested blocks.

---

## S017 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

---

## S018 — CONCEPT: Thanks for watching

**Thanks for watching**

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-02-meta-arguments/41-dynamic-blocks
```

Thanks for watching. If this helped, the full lab — along with every lab in this course — is in the GitHub repository linked in the description. See you in the next one.

---
