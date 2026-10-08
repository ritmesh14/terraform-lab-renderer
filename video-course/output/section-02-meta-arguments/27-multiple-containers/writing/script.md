# Script — Lab 27: Count On Demand: Driving count with a Variable

*Terraform Meta-arguments — Lab 27. Generated from `source/terraform-inventory.json` + `source/source-manifest.json` (ACTIVE_LAB = `section-02-meta-arguments/27-multiple-containers`).*

---

## S001 — TITLE: Count On Demand: Driving count with a Variable

**Count On Demand: Driving count with a Variable**

Welcome back to the course. Last lesson, count took one block and turned it into three — but the three was hard-coded. This is Lab 27, and we make that number configurable: count driven by an input variable, so a tfvars file — or one CLI flag — decides how many containers get created. Plus the validation block that keeps bad values out. Let's build it.

---

## S002 — CONCEPT: What you'll learn

- count accepts any number expression — not just a literal
- The validation block — bad values fail at plan time
- Scaling: change the variable, the plan follows

**What you'll learn**

Here's what you'll learn in this lesson — three things. One: count isn't limited to a literal — it accepts any number expression, and here a variable supplies it, so the number of containers is a setting, not a code edit. Two: the validation block — a rule that fails the plan early with a friendly message, instead of a cryptic Azure error after the first resource already landed. Three: what scaling looks like — change the variable, and the plan adds or removes exactly the difference.

---

## S003 — CONCEPT: Where this lab fits

- Lab 26: count = 3 — the fan-out was a literal
- This lab: count = var.container_count — a dial
- Later labs push the idea further: for_each and friends

**Where this lab fits**

This is the second lab of Section 2, Meta-arguments. In Lab 26 you met count with a literal — count equals three — and the fan-out was fixed the moment the code was written. This lab keeps the same one-block-many-copies idea but moves the number into a variable: the same configuration can create three containers today and ten tomorrow. Making the fan-out a parameter is the step that leads to for_each later in this section.

---

## S004 — CONCEPT: Where to find this lab

**Where to find this lab**

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-02-meta-arguments
          └── 27-multiple-containers
              ├── README.md
              ├── main.tf
              ├── terraform.tf
              └── variables.tf

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-02-meta-arguments/27-multiple-containers
```

You can find this lab in the course GitHub repository under Section 2, Meta-arguments — the lab named 27-multiple-containers. The direct link is in the video description. Open the two files we'll read in this lesson: main dot T F holds the whole configuration, and terraform dot T F pins the providers.

---

## S005 — CONCEPT: The mental model: a dial on the photocopier

- Lab 26's photocopier had a fixed setting — three copies
- A variable is a dial on the front panel
- The validation block is the guard next to the dial

**The mental model: a dial on the photocopier**

Before any code, here's the mental model. Lab 26's photocopier had its number of copies hard-wired — always three. Now the number comes from a dial on the front panel: an input variable. Want three containers? Set the dial. Want seven? Turn it — without rewriting the machine's internals, the resource block. And standing next to the dial is a guard: the validation block, which checks the setting before the plan runs and refuses impossible values on the spot.

---

## S006 — CODE

The configuration lives in two files. Terraform dot T F pins the tooling: Terraform 1.5 or newer, the azurerm provider around version 3.70, and the random provider — this lab uses it again for a unique suffix. The provider block at the bottom is the bridge to Azure; the empty features block enables the provider's default behaviours. Nothing new in this file — the change in this lab is all in main dot T F.

---

## S007 — CODE

**Steps:**

1. The new piece sits at the top of main dot T F: an input variable named container_count. Its type is number, and its default is three — so with no extra input at all, this lab behaves exactly like the last one.
   - active: [8, 9, 10]
2. Then the validation block — a rule Terraform checks at plan time. The condition has to be true: the value must be above zero and at most ten. Pass eleven, or zero, and the plan stops right there with the friendly message you wrote — before a single resource is even planned.
   - active: [11, 12, 13, 14]

The new piece sits at the top of main dot T F: an input variable named container_count. Its type is number, and its default is three — so with no extra input at all, this lab behaves exactly like the last one. Then the validation block — a rule Terraform checks at plan time. The condition has to be true: the value must be above zero and at most ten. Pass eleven, or zero, and the plan stops right there with the friendly message you wrote — before a single resource is even planned.

---

## S008 — CODE

**Steps:**

1. Next, the locals block computes names once. The storage account name is lowercased with a random suffix appended — locals simply hold the value so it's written in one place.
   - active: [20, 21]
2. The suffix comes from random_string: six lowercase characters. Because it's a resource — not a function — the value is saved in state, so every future plan and apply keeps the same suffix and names never drift between runs.
   - active: [27, 28, 29, 30, 31]

Next, the locals block computes names once. The storage account name is lowercased with a random suffix appended — locals simply hold the value so it's written in one place. The suffix comes from random_string: six lowercase characters. Because it's a resource — not a function — the value is saved in state, so every future plan and apply keeps the same suffix and names never drift between runs.

---

## S009 — CODE

**Steps:**

1. The resource group gets a fixed name — rg dash multi dash containers.
   - active: [34, 35, 36, 37]
2. The storage account references the group for its name and location — that reference is an implicit dependency, so the group is always created first. Its own name comes from locals, with the random suffix baked in.
   - active: [42, 43, 44, 45]

The resource group gets a fixed name — rg dash multi dash containers. The storage account references the group for its name and location — that reference is an implicit dependency, so the group is always created first. Its own name comes from locals, with the random suffix baked in.

---

## S010 — CODE

**Steps:**

1. And here is the one line that changed from last lab. It's still an ordinary container block with a count — but now count reads the variable: count equals var dot container_count. The number of copies is whatever the caller set.
   - active: [51, 52]
2. Inside each copy, everything from last lab still applies: count dot index is the copy's number, and the name interpolates it in — tier-0, tier-1, tier-2.
   - active: [53]
3. Each copy also references the storage account, so every instance waits for the account. And nothing in this block is hard-wired to three anymore — the same code serves one container or ten.
   - active: [54, 55]

And here is the one line that changed from last lab. It's still an ordinary container block with a count — but now count reads the variable: count equals var dot container_count. The number of copies is whatever the caller set. Inside each copy, everything from last lab still applies: count dot index is the copy's number, and the name interpolates it in — tier-0, tier-1, tier-2. Each copy also references the storage account, so every instance waits for the account. And nothing in this block is hard-wired to three anymore — the same code serves one container or ten.

---

## S011 — ITERATION_EXPANSION: One variable, any number of copies

**One variable, any number of copies**

**Steps:**

1. The dial starts at three — that's the variable's default.
2. count reads the variable and expands the block into three instances — data zero, data one, data two, exactly like last lab.
3. Inside copy two — the one at index one — count dot index is one, so its name becomes tier-1. The other copies do the same with their own numbers.
4. Now the payoff: terraform apply dash var container_count equals 5 — or one line in terraform dot tfvars — and the same block expands into five instances. The dial turned; no code was touched.

The dial starts at three — that's the variable's default. count reads the variable and expands the block into three instances — data zero, data one, data two, exactly like last lab. Inside copy two — the one at index one — count dot index is one, so its name becomes tier-1. The other copies do the same with their own numbers. Now the payoff: terraform apply dash var container_count equals 5 — or one line in terraform dot tfvars — and the same block expands into five instances. The dial turned; no code was touched.

---

## S012 — CODE

**Steps:**

1. The outputs read the counted list back. A counted resource is a list, so length counts its entries — and that number is whatever the caller chose.
   - active: [61]
2. The splat you met last lab collects the name from every instance — so container underscore names prints the whole list, whatever its length.
   - active: [62]

The outputs read the counted list back. A counted resource is a list, so length counts its entries — and that number is whatever the caller chose. The splat you met last lab collects the name from every instance — so container underscore names prints the whole list, whatever its length.

---

## S013 — CONCEPT: Scaling: moving the dial

- Raise 3 → 5: the plan adds data[3] and data[4]
- Lower 5 → 3: the plan destroys data[3] and data[4]
- Kept instances keep their addresses — no churn

**Scaling: moving the dial**

So what actually happens when the dial moves? Raise container_count from three to five, and the next plan adds exactly two entries — data in brackets three and data in brackets four, the highest new indexes. Lower it back to three, and the plan destroys those same two. The kept instances hold onto their addresses and are never touched. That's the flip side of the positional addressing from last lab: scaling is cheap for throwaway names — and something to think about when real data lives in the higher indexes.

---

## S014 — DIAGRAM: How the pieces connect

**How the pieces connect**

**Steps:**

1. Here's how the pieces connect.
2. On the left, the input variable holds the number — the dial.
   - active: ['var']
3. The random string generates the suffix and saves it in state.
   - active: ['random']
4. Locals take that suffix and compute the storage account's name.
   - active: ['locals']
5. The resource group groups everything in Azure.
   - active: ['rg']
6. The storage account references the group — that's the dependency: group first, account second. Its own name came from locals, with the random suffix baked in.
   - active: ['st']
7. And the containers: count reads the variable, so one block fans out into exactly as many containers as the caller chose.
   - active: ['containers']
8. The outputs read the copies back: length counts them, and the splat collects every name.
   - active: ['out']
9. Everything lands inside your Azure subscription.

Here's how the pieces connect. On the left, the input variable holds the number — the dial. The random string generates the suffix and saves it in state. Locals take that suffix and compute the storage account's name. The resource group groups everything in Azure. The storage account references the group — that's the dependency: group first, account second. Its own name came from locals, with the random suffix baked in. And the containers: count reads the variable, so one block fans out into exactly as many containers as the caller chose. The outputs read the copies back: length counts them, and the splat collects every name. Everything lands inside your Azure subscription.

---

## S015 — TERMINAL

Here's the plan with the dial turned to five — terraform plan dash var container_count equals 5 — an illustrative view. Look at the header: the variable's value is five. Count the entries: the random string, the group, the account, and five containers — data in brackets zero through data in brackets four. The same block, five copies — decided by the variable, not the code.

---

## S016 — TERMINAL

And here is the guard at work — an illustrative run with container_count set to eleven. The plan never reaches Azure: it stops at the variable, with the exact message written in the validation block — keep between one and ten. That's the value of a validation block: bad input dies at plan time, on your machine, before a single resource is touched.

---

## S017 — CONCEPT: Common pitfall

- count from a variable scales — but addresses stay positional
- Lowering the count destroys the highest instances — and their data
- Validation guards the variable only — other mistakes bypass it

**Common pitfall**

One pitfall to understand before you make count configurable everywhere. One: a variable makes the fan-out configurable, but the addresses are still positional — data zero through data N — just like last lab. Two: that matters most when the dial goes down: the highest instances are the ones destroyed, and if they hold real data, shrinking a count is a deletion. Check what lives at the highest indexes before you lower it. And three: the validation block guards only the variable it lives in — it's an input check, not a code review; mistakes elsewhere in the configuration sail right past it.

---

## S018 — RECAP

- count = var.container_count — the fan-out is a setting
- The validation block fails bad values at plan time
- Raising the variable adds the highest new indexes
- Lowering destroys the highest indexes — mind real data
- length() and the splat [*] flex with the count

Quick recap — five things. One: count now reads a variable — count equals var dot container count — so the fan-out is a setting, not a code edit. Two: the validation block checks the value at plan time and fails early with a friendly message. Three: raising the variable adds the highest new indexes — data three, data four. Four: lowering it destroys the highest indexes first — mind what lives there. Five: the outputs flex with the count — length counts the list, the splat collects every name. One block, and the caller decides how many.

---

## S019 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

---

## S020 — CONCEPT: Thanks for watching

**Thanks for watching**

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-02-meta-arguments/27-multiple-containers
```

Thanks for watching. If this helped, the full lab — along with every lab in this course — is in the GitHub repository linked in the description. See you in the next one.

---
