# Script — Lab 26: One Block, Many Resources: The count Meta-argument

*Terraform Meta-arguments — Lab 26. Generated from `source/terraform-inventory.json` + `source/source-manifest.json` (ACTIVE_LAB = `section-02-meta-arguments/26-count-meta-argument`).*

---

## S001 — TITLE

**One Block, Many Resources: The count Meta-argument**

Welcome back to the course. Through all of Section 1, every resource block you wrote created exactly one thing. Today that changes. This is Lab 26, and it opens the Meta-arguments section with the most-used one of them all: count. One block of code — three containers in Azure. Let's see how.

---

## S002 — CONCEPT: What you'll learn

- count — run one resource block N times
- count.index — the number of the copy you're inside
- The splat [*] — collect all copies' values into one list

Here's what you'll learn in this lesson — three things. One: count — a meta-argument that runs one resource block N times, so three lines of code become three real containers. Two: count dot index — inside each copy, this tells you which number you're on, and that's how each container gets its own name. Three: the splat — star inside square brackets — which collects a value from every copy into one list, so a single output can show all three container names. Write once, create many, read them all back — that's the whole lab.

---

## S003 — CONCEPT: Where this lab fits

- First lab of the Meta-arguments section
- Section 1: every block created exactly one resource
- Now: one block can create many

This is the first lab of Section 2, Meta-arguments. Throughout Section 1, every resource block you wrote created exactly one thing — one resource group, one storage account. Meta-arguments change that. They are special arguments every resource understands, and count is the one that turns one block into many. It's the foundation the rest of this section builds on.

---

## S004 — CONCEPT: Where to find this lab

*GitHub breadcrumb (never read aloud): `RIT-MESH / Terraform-Azure-Labs-and-Case_Studies →   └── labs →       └── section-02-meta-arguments →           └── 26-count-meta-argument →               ├── README.md →               ├── main.tf →               └── terraform.tf →  → https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies → /tree/master/labs/section-02-meta-arguments/26-count-meta-argument`*

You can find this lab in the course GitHub repository under Section 2, Meta-arguments — the lab named 26-count-meta-argument. The direct link is in the video description. Open the two files we'll read in this lesson: main dot T F holds the whole configuration, and terraform dot T F pins the providers.

---

## S005 — CONCEPT: The mental model: a photocopier

- Write the block once — Terraform copies it N times
- Each copy is a real, separate resource
- Each copy carries a number: 0, 1, 2

Before any code, here's the mental model. Think of count as a photocopier. You write the resource block once — that's your original. Terraform presses copy three times, and each copy becomes a real, separate resource in Azure. And just like pages coming out of a copier, each copy is numbered: copy zero, copy one, copy two. Nothing inside the block changes — only how many times Terraform stamps it out.

---

## S006 — CODE: terraform.tf (lines 1–23)

The configuration lives in two files. Terraform dot T F pins the tooling: Terraform 1.5 or newer, the azurerm provider around version 3.70, and the random provider — that one matters here, because we'll use it to generate a unique suffix for our names. The provider block at the bottom is the bridge to Azure; the empty features block enables the provider's default behaviours.

---

## S007 — CODE: main.tf (lines 7–19)

**Step 1** (active lines: 7, 8, 9, 10)

At the top of main dot T F, the locals block computes names once. The resource group gets a fixed name, and the storage account name is lowercased with a random suffix appended — locals simply hold the values so we write them in one place.

**Step 2** (active lines: 15, 16, 17, 18, 19)

That suffix comes from random_string: six lowercase characters. Because it's a resource — not a function — the value is saved in state. Every future plan and apply keeps the same suffix, so names never drift between runs.

---

## S008 — CODE: main.tf (lines 22–37)

**Step 1** (active lines: 22, 23, 24, 25)

Then the two single-instance blocks — the same pattern you know from Section 1. The resource group takes its name from locals.

**Step 2** (active lines: 31, 32, 33, 34, 35, 36, 37)

And the storage account. Notice it references the resource group by attribute — name and location — instead of repeating strings. Those references create implicit dependencies, so Terraform always creates the group first, without you listing any order.

---

## S009 — CODE: main.tf (lines 41–46)

**Step 1** (active lines: 41, 42)

And here is the star of the lab. An ordinary container block — with one extra line. count equals 3. That single line tells Terraform: create three copies of this block.

**Step 2** (active lines: 43)

Inside a counted resource, count dot index is the number of the current copy — zero for the first, one for the second, two for the third.

**Step 3** (active lines: 43)

We use it in the name: data dash, then the index interpolated in. Copy zero becomes data-0, copy one becomes data-1, copy two becomes data-2. Three containers, one block, and every copy named automatically.

---

## S010 — ITERATION_EXPANSION: count = 3

**Step 1** (focus: expr)

Watch what count equals 3 does to this one block.

**Step 2** (focus: inst)

Terraform expands it into three instances, and each instance gets a state address with its index in brackets: data zero, data one, data two.

**Step 3** (focus: inst, names, i1, n1)

Inside copy two — the one at index one — count dot index is one, so its name becomes data-1. The other copies do the same with their own numbers.

**Step 4** (focus: names)

Three names, derived from three indexes — and not one line of copy-paste in the source.

---

## S011 — CODE: main.tf (lines 48–53)

**Step 1** (active lines: 51, 52, 53)

After apply, you'll want the names back. The output block does that. But here's the twist: once a resource uses count, Terraform stores it as a list — not one object. The address azurerm_storage_container dot data now points at all three instances at once.

**Step 2** (active lines: 52)

The splat — star in square brackets — says: walk every instance in that list, take dot name from each, and hand me all of them. One expression, three values.

---

## S012 — STATE_ADDRESS: azurerm_storage_container.data[*].name

**Step 1** (focus: addr, a0, a1, a2)

In state, the three containers live at indexed addresses: data zero, data one, data two — one entry per copy.

**Step 2** (focus: addr, all)

The splat means every instance — all of them, no matter how many count created.

**Step 3** (focus: pick, out)

From each instance it takes the name attribute, and the result is one tidy list — exactly what the output prints after apply.

---

## S013 — CONCEPT: Ordering: references do the work

- Storage account references the resource group → implicit dependency
- Containers reference the storage account → created after it
- You never list the order — the references define it

One thing worth slowing down for: the order Terraform creates things. We never told it an order anywhere in the code. The storage account references the resource group's name and location — that reference is an implicit dependency, so the group is always created first. The containers reference the storage account's name, so they come after it. References define the order; Terraform builds the graph, and you never maintain it by hand.

---

## S014 — DIAGRAM: How the pieces connect

**Step 1** — Here's how the pieces connect.

**Step 2** — The random string generates the suffix and saves it in state.

**Step 3** — Locals take that suffix and compute the names.

**Step 4** — The resource group takes its name from locals.

**Step 5** — The storage account references the group — that's the dependency: group first, account second. Its own name came from locals, with the random suffix baked in.

**Step 6** — And count equals 3 stamps three containers out of one block, all inside the storage account.

**Step 7** — The output splats all three names into one list.

**Step 8** — Everything lands inside your Azure subscription.

---

## S015 — TERMINAL (lab26-plan)

Here's the plan this configuration produces — an illustrative view, of course. Count the entries: the random string, the group, the account, and three containers. And look at the addresses: data in brackets zero, data in brackets one, data in brackets two. That's count at work — one block in the code, three entries in the plan.

---

## S016 — TERMINAL (lab26-apply)

Apply it, and the same story lands in Azure — illustrative again. Six resources created. And the output prints the splat's result: one list holding data-0, data-1 and data-2. One expression in the code, all three names in your terminal.

---

## S017 — CONCEPT: Common pitfall

- Addresses are positional: data[1] is simply "whatever is second"
- Reordering or removing a middle copy shifts every later address
- for_each (later lab) addresses instances by stable key instead

One pitfall to understand before you lean on count in production. One: count's addresses are positional — data in brackets one is simply whatever sits second in the list. So if you reorder the block, or remove a copy from the middle, every later address shifts: what used to be data-2 suddenly becomes data-1. Terraform sees the address change and will destroy and recreate those containers to match. That's harmless for throwaway names like these — it's a real problem when the resource holds data. The fix is a different meta-argument: for_each, which addresses instances by a stable key instead of a position. We'll cover it later in this section.

---

## S018 — RECAP

- count = 3 — one block, three identical copies
- count.index — the copy's number: 0, 1, 2
- Names come straight from the index: data-0, data-1, data-2
- A counted resource is a list — the splat [*] collects them
- Addresses are positional: data[0] through data[2]

Quick recap — five things. One: count equals 3 turned one container block into three identical copies. Two: count dot index is the copy's number — zero, one, two. Three: the names came straight from that index — data-0, data-1, data-2. Four: a counted resource is a list, and the splat collected all three names into the output. Five: the addresses are positional — data in brackets zero through two — so for count, position is identity.

---

## S019 — NEXT (fixed transition)

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

---

## S020 — CONCEPT: Thanks for watching

*GitHub breadcrumb (never read aloud): `github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies → tree/master/labs/section-02-meta-arguments/26-count-meta-argument`*

Thanks for watching. If this helped, the full lab — along with every lab in this course — is in the GitHub repository linked in the description. See you in the next one.

---
