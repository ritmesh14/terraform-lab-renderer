# Script — Lab 47: Feature Flags: Conditional Resources

*Terraform Meta-arguments — Lab 47. Generated from `source/terraform-inventory.json` + `source/source-manifest.json` (ACTIVE_LAB = `section-02-meta-arguments/47-conditional-resources`).*

---

## S001 — TITLE: Feature Flags: Conditional Resources

**Feature Flags: Conditional Resources**

Welcome back. So far every resource block we wrote always created its resource. This is Lab 47, and one resource becomes optional: count equals a boolean flag, question one, colon zero. Flip the flag and the NSG appears or vanishes — while the network around it never moves. Terraform has no if statement; this is the idiom that stands in for one. Let's build it.

---

## S002 — CONCEPT: What you'll learn

- count = var.deploy_nsg ? 1 : 0 — the idiomatic "if" in Terraform
- count makes the resource a LIST — the single instance is web[0]
- Every dependent resource needs the SAME flag — the association too

**What you'll learn**

Three things in this lesson. One: the conditional idiom itself — count equals a ternary: one instance when the flag is true, zero instances — meaning the resource exists NOWHERE — when it's false. Two: the addressing consequence — count turns the resource into a list, so even a single instance is addressed web bracket zero. Three: the rule that keeps it working — every resource that depends on the flagged one must carry the SAME flag, or it references an instance that doesn't exist.

---

## S003 — CONCEPT: Where this lab fits

- Lab 27: count = N — a fixed number of instances
- This lab: count = condition ? 1 : 0 — the count that decides ITSELF
- The ternary you met in lab 42's fileexists guard now controls resources

**Where this lab fits**

Placement. Lab 27 gave you count as a number — three subnets, fixed. This lab makes the count ITSELF conditional: a ternary expression, exactly the question mark colon form you met in lab 42 guarding the file read. Same operator, bigger stakes — now it decides whether a resource exists at all. This is the last new shape for count; everything after builds on fan-outs you already own.

---

## S004 — CONCEPT: Where to find this lab

**Where to find this lab**

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-02-meta-arguments
          └── 47-conditional-resources

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-02-meta-arguments/47-conditional-resources
```

You'll find this lab in the course GitHub repository under Section 2, Meta-arguments — the lab named 47-conditional-resources. The direct link is in the video description. One main dot T F — the terraform block is inline at the top.

---

## S005 — CODE

No separate terraform dot T F this time — the tooling block is inline at the top of main dot T F: Terraform 1.5 or newer, and the azurerm provider around version 3.70. The provider block below bridges to Azure; the empty features block enables the provider's defaults.

---

## S006 — CODE

**Steps:**

1. The input is a plain boolean: deploy nsg, defaulting to true. The comment above says exactly what it is — a feature flag. Callers flip it with dash var; nothing else in the config changes.
   - active: [21, 22, 23, 24]

The input is a plain boolean: deploy nsg, defaulting to true. The comment above says exactly what it is — a feature flag. Callers flip it with dash var; nothing else in the config changes.

---

## S007 — CODE

**Steps:**

1. The locals carry a small twist worth noticing: the VNet is a slash 20 and the subnet a slash 26 — not the slash 16 slash 24 pair from earlier labs. The comment makes the point: block sizes only have to NEST. The /16 plus /24 was convention, not a rule.
   - active: [29, 30, 31]

The locals carry a small twist worth noticing: the VNet is a slash 20 and the subnet a slash 26 — not the slash 16 slash 24 pair from earlier labs. The comment makes the point: block sizes only have to NEST. The /16 plus /24 was convention, not a rule.

---

## S008 — CODE

**Steps:**

1. The network that is ALWAYS created: resource group from local dot rg, VNet vnet dash conditional on the /20. No count here — these never depend on the flag.
   - active: [35, 36, 42, 45]
2. And the subnet: snet web, the /26 nested inside the VNet — also unconditional. Only the NSG below is a flag.
   - active: [50, 53]

The network that is ALWAYS created: resource group from local dot rg, VNet vnet dash conditional on the /20. No count here — these never depend on the flag. And the subnet: snet web, the /26 nested inside the VNet — also unconditional. Only the NSG below is a flag.

---

## S009 — CODE

**Steps:**

1. Here it is — the conditional resource. Count equals var dot deploy nsg, question one, colon zero. Flag true: one instance, addressed web bracket zero. Flag false: count is zero, the resource exists nowhere in Azure — not created-and-disabled, simply absent from the plan. The NSG block below it is an ordinary NSG — nsg dash conditional; the count line is the whole trick.
   - active: [57, 58, 59]

Here it is — the conditional resource. Count equals var dot deploy nsg, question one, colon zero. Flag true: one instance, addressed web bracket zero. Flag false: count is zero, the resource exists nowhere in Azure — not created-and-disabled, simply absent from the plan. The NSG block below it is an ordinary NSG — nsg dash conditional; the count line is the whole trick.

---

## S010 — CODE

**Steps:**

1. And the association carries the SAME flag: count equals var dot deploy nsg question one colon zero, line for line with the NSG. Because count makes the NSG a list, the reference is web bracket zero dot id — the single instance. Drop either half and the config breaks: without the flag, the association would reference an NSG that doesn't exist; without the bracket zero, the reference doesn't type-check.
   - active: [65, 66, 67, 68]

And the association carries the SAME flag: count equals var dot deploy nsg question one colon zero, line for line with the NSG. Because count makes the NSG a list, the reference is web bracket zero dot id — the single instance. Drop either half and the config breaks: without the flag, the association would reference an NSG that doesn't exist; without the bracket zero, the reference doesn't type-check.

---

## S011 — CODE

**Steps:**

1. The output echoes the flag itself: nsg created equals var dot deploy nsg. Scripts can read the decision from outputs without parsing state — a small touch that makes the feature flag observable.
   - active: [72]

The output echoes the flag itself: nsg created equals var dot deploy nsg. Scripts can read the decision from outputs without parsing state — a small touch that makes the feature flag observable.

---

## S012 — CONCEPT: The feature-flag pattern

- Terraform has no `if` — count = condition ? 1 : 0 is the idiom
- count = 0 means the resource exists NOWHERE — not created-but-disabled
- Flipping the flag is a clean toggle: plan previews the destroy first

**The feature-flag pattern**

Worth pausing on what this pattern IS. Terraform deliberately has no if statement — HCL describes state, it doesn't branch; count with a ternary is the sanctioned stand-in. And count zero is stronger than disabled: the resource is entirely absent from the plan and the state — nothing in Azure, nothing to pay for. The payoff is the workflow: flip the flag with dash var, and terraform plan previews exactly what would be destroyed — you see the toggle before you commit it.

---

## S013 — DIAGRAM: How the pieces connect

**How the pieces connect**

**Steps:**

1. Here's how the pieces connect.
2. The feature flag: deploy nsg — a boolean, defaulting to true.
   - active: ['flag']
3. The always-created network: resource group, VNet, subnet.
   - active: ['rg', 'vnet', 'subnet']
4. The NSG — conditional. Count equals the ternary: one instance when true, ZERO when false.
   - active: ['nsg']
5. The association carries the same flag and references the single instance, web bracket zero.
   - active: ['assoc']
6. Everything lands inside your Azure subscription.

Here's how the pieces connect. The feature flag: deploy nsg — a boolean, defaulting to true. The always-created network: resource group, VNet, subnet. The NSG — conditional. Count equals the ternary: one instance when true, ZERO when false. The association carries the same flag and references the single instance, web bracket zero. Everything lands inside your Azure subscription.

---

## S014 — TERMINAL

Here's the plan with the flag at its default — terraform plan, an illustrative view. Five to add: resource group, VNet, subnet, NSG, and the association. The NSG is just another resource in the list — the flag is true, so count is one.

---

## S015 — TERMINAL

Now flip it — terraform plan with dash var deploy nsg equals false, after that first apply. An illustrative view: zero to add, TWO to destroy — the NSG and its association. The VNet, subnet and resource group are untouched. That's the whole feature-flag idea: one variable, one plan preview, a clean toggle with nothing tainted.

---

## S016 — CONCEPT: Common pitfall

- Dependent resources MUST carry the same flag — otherwise they reference a missing instance
- count makes a LIST — address the single instance as web[0], not web
- count = 0 removes the resource entirely — data that referenced it fails too

**Common pitfall**

Three pitfalls. One: every dependent resource needs the same flag — here the association; forget its count and the plan fails trying to reference an NSG instance that doesn't exist. Two: count turns the resource into a list even at size one — the address is web bracket zero; referencing bare web fails to type-check. Three: remember what zero means — the resource is gone entirely, so anything downstream that reads it, outputs or other configs, fails too. A flag flips an entire subtree, not just one block.

---

## S017 — RECAP

- count = var.deploy_nsg ? 1 : 0 — Terraform's idiomatic feature flag
- count = 0 → the resource exists nowhere in plan, state, or Azure
- count makes the resource a list — the single instance is web[0]
- The association carries the SAME flag — dependent resources match
- CIDRs only have to nest — /20 VNet + /26 subnet is perfectly legal

Quick recap — five things. One: count equals a boolean ternary is Terraform's if statement — one instance or none. Two: zero means absent everywhere — plan, state, Azure. Three: count makes the resource a list, so even one instance is web bracket zero. Four: dependents carry the same flag — the association here. Five: a side lesson from the locals — CIDR blocks only need to nest; the /16-plus-/24 pairing was habit, not law. Terraform now has a feature flag.

---

## S018 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

---

## S019 — CONCEPT: Thanks for watching

**Thanks for watching**

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-02-meta-arguments/47-conditional-resources
```

Thanks for watching. If this helped, the full lab — along with every lab in this course — is in the GitHub repository linked in the description. See you in the next one.

---
