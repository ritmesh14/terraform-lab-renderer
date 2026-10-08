# Script — Lab 32: Same Copies, Polished Names: count + format()

*Terraform Meta-arguments — Lab 32. Generated from `source/terraform-inventory.json` + `source/source-manifest.json` (ACTIVE_LAB = `section-02-meta-arguments/32-multiple-public-ips`).*

---

## S001 — TITLE: Same Copies, Polished Names: count + format()

**Same Copies, Polished Names: count + format()**

Welcome back. Four labs of for_each — now count gets its polish. This is Lab 32: three identical public IPs, created with count, named with format so they come out pip zero one, pip zero two, pip zero three — zero-padded, sorted, tidy. And the output teaches one more symbol: the splat. Let's build it.

---

## S002 — CONCEPT: What you'll learn

- count driven by a local — one number scales the fan-out
- format() with %02d — zero-padded names from count.index
- The [*] splat — collect one attribute from every instance

**What you'll learn**

Three things in this lesson. One: count driven by a local — change one number, re-apply, and the fan-out scales. Two: format with the percent zero two d placeholder — zero-padded names computed from count dot index. Three: the splat — star in brackets — the short expression that collects one attribute from every count instance into a list.

---

## S003 — CONCEPT: Where this lab fits

- Labs 28–31: for_each — named copies, keyed addresses
- This lab: count again — right tool when copies are identical
- The splat returns in the state-addressing lesson

**Where this lab fits**

Placement. Labs 28 through 31 were all for_each — named copies, keyed addresses. This lab deliberately returns to count, because these three public IPs are truly identical: no copy has a meaning the others lack, so numbers are fine. Count is not the enemy — it's the right tool for identical things, and this lab shows its best form. The splat at the end returns again when we talk about state addressing.

---

## S004 — CONCEPT: Where to find this lab

**Where to find this lab**

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-02-meta-arguments
          └── 32-multiple-public-ips

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-02-meta-arguments/32-multiple-public-ips
```

You'll find this lab in the course GitHub repository under Section 2, Meta-arguments — the lab named 32-multiple-public-ips. The direct link is in the video description. Main dot T F holds everything; terraform dot T F pins the providers.

---

## S005 — CODE

Two files matter here, and the first is terraform dot T F. It pins the tooling: Terraform 1.5 or newer, and the azurerm provider around version 3.70 — nothing else, because this lab needs no extras. The provider block at the bottom is the bridge to Azure; the empty features block enables the provider's default behaviours. That's the whole file — every interesting line lives in main dot T F.

---

## S006 — CODE

**Steps:**

1. The whole fan-out is controlled by one number: locals holds ip count equals three. Change that number, re-apply, and Azure gains or loses public IPs — nothing else in the file mentions the count.
   - active: [7, 8, 9]
2. The resource group is the usual container — rg dash multi dash pips. Note this lab has no VNet at all: public IPs don't need one.
   - active: [12, 13, 14, 15]

The whole fan-out is controlled by one number: locals holds ip count equals three. Change that number, re-apply, and Azure gains or loses public IPs — nothing else in the file mentions the count. The resource group is the usual container — rg dash multi dash pips. Note this lab has no VNet at all: public IPs don't need one.

---

## S007 — CODE

**Steps:**

1. One public IP block, count equals local dot ip count. Terraform will expand this single block into three instances — this[0], this[1], this[2].
   - active: [19]
2. The name is where format earns its keep: format, quote pip percent zero two d quote, count dot index plus one. Percent zero two d means: print the number as an integer, padded with zeros to at least two digits. So index zero plus one gives pip dash zero one — not pip dash 1.
   - active: [20]
3. Why pad? Because plain sorting would put pip dash 10 before pip dash 2. Zero-padded names sort correctly as strings — pip zero two always sits between pip zero one and pip zero three, no matter how far the count grows.
   - active: [20]
4. The rest is standard: static allocation on the standard SKU, so each address survives deallocations — and the three instances stay independent.
   - active: [22, 23, 24, 25]

One public IP block, count equals local dot ip count. Terraform will expand this single block into three instances — this[0], this[1], this[2]. The name is where format earns its keep: format, quote pip percent zero two d quote, count dot index plus one. Percent zero two d means: print the number as an integer, padded with zeros to at least two digits. So index zero plus one gives pip dash zero one — not pip dash 1. Why pad? Because plain sorting would put pip dash 10 before pip dash 2. Zero-padded names sort correctly as strings — pip zero two always sits between pip zero one and pip zero three, no matter how far the count grows. The rest is standard: static allocation on the standard SKU, so each address survives deallocations — and the three instances stay independent.

---

## S008 — ITERATION_EXPANSION: One block, three numbered instances

**One block, three numbered instances**

**Steps:**

1. The expression is one line: count equals local dot ip count — the number three.
2. Terraform expands it into three instances addressed by position — this bracket zero, bracket one, bracket two.
3. And each instance's name comes from format and count dot index: index zero becomes pip zero one — plus one turns the zero-based index into a human count.

The expression is one line: count equals local dot ip count — the number three. Terraform expands it into three instances addressed by position — this bracket zero, bracket one, bracket two. And each instance's name comes from format and count dot index: index zero becomes pip zero one — plus one turns the zero-based index into a human count.

---

## S009 — CODE

**Steps:**

1. The output uses the symbol this lab is really about: azurerm_public_ip dot this, star in brackets, dot ip_address. That star-in-brackets is the splat — it means: for every instance of this counted resource, take ip_address, and give me the list.
   - active: [30]
2. One more thing the comment flags: ip_address is only known AFTER apply — Azure assigns it, not Terraform. So the plan shows a placeholder, and the real three addresses appear once the apply finishes.
   - active: [30]

The output uses the symbol this lab is really about: azurerm_public_ip dot this, star in brackets, dot ip_address. That star-in-brackets is the splat — it means: for every instance of this counted resource, take ip_address, and give me the list. One more thing the comment flags: ip_address is only known AFTER apply — Azure assigns it, not Terraform. So the plan shows a placeholder, and the real three addresses appear once the apply finishes.

---

## S010 — STATE_ADDRESS: The splat: many instances, one attribute, one list

**The splat: many instances, one attribute, one list**

**Steps:**

1. Start from the instances: three counted copies, addressed by index in state.
2. Each instance carries the same attribute — ip address — and each value is unknown until Azure assigns it at apply time.
3. The splat is the expression that walks all of them at once — star in brackets means every instance, no loop written by hand.
4. And the result is one list of three addresses — which is exactly what the output prints after apply.

Start from the instances: three counted copies, addressed by index in state. Each instance carries the same attribute — ip address — and each value is unknown until Azure assigns it at apply time. The splat is the expression that walks all of them at once — star in brackets means every instance, no loop written by hand. And the result is one list of three addresses — which is exactly what the output prints after apply.

---

## S011 — DIAGRAM: How the pieces connect

**How the pieces connect**

**Steps:**

1. Here's how the pieces connect.
2. Locals hold the one number that scales everything: ip count three.
   - active: ['locals']
3. The resource group groups everything in Azure.
   - active: ['rg']
4. The public IPs: count expands one block into three instances, and format turns each index into a zero-padded name.
   - active: ['pips']
5. The output splats ip_address off every instance into a list.
   - active: ['out']
6. Everything lands inside your Azure subscription.

Here's how the pieces connect. Locals hold the one number that scales everything: ip count three. The resource group groups everything in Azure. The public IPs: count expands one block into three instances, and format turns each index into a zero-padded name. The output splats ip_address off every instance into a list. Everything lands inside your Azure subscription.

---

## S012 — TERMINAL

Here's the plan — terraform plan, an illustrative view. The resource group, then three public IPs: pip dash zero one, pip dash zero two, pip dash zero three — each with a named argument marked sensitive where secrets would appear. Four to add, zero to destroy. One block in the code; three numbered copies in the plan.

---

## S013 — TERMINAL

And after apply, the output — terraform output ips, an illustrative view. The splat delivered exactly what it promised: a list of three addresses, in index order. During plan these were placeholders; Azure assigned the real values at apply.

---

## S014 — CONCEPT: Common pitfall

- count.index is zero-based — the +1 in format() makes it human
- Splat on a counted resource is a list — index it, don't map it
- Removing the middle IP shifts every later address — recreations

**Common pitfall**

Three pitfalls. One: count dot index starts at zero — the plus one inside format is what makes pip zero one the first name; forget it and your first IP is pip zero zero. Two: the splat on a counted resource always yields a list — address elements by position; if you need named access, that's for_each territory. And three, the count classic: IPs are addressed by position, so destroying the middle one shifts every later address — Terraform sees new names at old positions and wants to recreate. Identical, interchangeable things only.

---

## S015 — RECAP

- count = local.ip_count — one number scales the fan-out
- format("pip-%02d", count.index + 1) — zero-padded names
- Zero padding keeps names sorting correctly as the count grows
- this[*].ip_address — the splat collects one attribute into a list
- ip_address is known after apply — placeholders during plan

Quick recap — five things. One: count reads a local, so one number scales the whole fan-out. Two: format with percent zero two d turns count dot index plus one into zero-padded names. Three: the padding isn't decoration — it keeps names sorting correctly as the count grows past nine. Four: the splat collects one attribute from every instance into a single list. Five: that attribute is known after apply — plan shows placeholders, apply fills in the real values. Count for identical things — named and polished.

---

## S016 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

---

## S017 — CONCEPT: Thanks for watching

**Thanks for watching**

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-02-meta-arguments/32-multiple-public-ips
```

Thanks for watching. If this helped, the full lab — along with every lab in this course — is in the GitHub repository linked in the description. See you in the next one.

---
