# Script — Lab 50: Two Dynamic Blocks: NSG Rules + Multi-IP NIC

*Terraform Meta-arguments — Lab 50. Generated from `source/terraform-inventory.json` + `source/source-manifest.json` (ACTIVE_LAB = `section-02-meta-arguments/50-dynamic-multi`).*

---

## S001 — TITLE: Two Dynamic Blocks: NSG Rules + Multi-IP NIC

**Two Dynamic Blocks: NSG Rules + Multi-IP NIC**

Welcome back. Lab 41 gave you the dynamic block — one block, many copies. This is Lab 50, the section capstone, and it runs the pattern TWICE in one configuration: an NSG whose security rules come from a variable list, and a NIC whose ip configurations come from another — two static IPs on one machine. Extend either list, re-apply, and the anatomy follows the data. Let's build it.

---

## S002 — CONCEPT: What you'll learn

- TWO dynamic blocks in one config — security_rule + ip_configuration
- The iterator name comes from the block LABEL — security_rule.value, ip_configuration.value
- Multi-IP NIC: Static allocation, explicit private_ip_address, one primary

**What you'll learn**

Three things in this lesson. One: the scale-up — two independent dynamic blocks in one configuration, each driven by its own variable list. Two: the addressing detail that trips everyone — inside content, the iterator is the BLOCK's label dot value, so security rule dot value on the NSG and ip configuration dot value on the NIC; not each dot value. Three: the multi-IP pattern — static allocation with explicit addresses, and exactly one configuration marked primary.

---

## S003 — CONCEPT: Where this lab fits

- Lab 41: ONE dynamic block (NSG security_rule) — the pattern itself
- This lab: the pattern at TWO levels + the section capstone
- Labs 46–49 all feed in: flag-free fan-out, keyed values, caller-owned anatomy

**Where this lab fits**

Placement. Lab 41 taught the dynamic block once, on one NSG. This lab runs it twice and adds the multi-IP NIC — and it's the section capstone: variables that own the anatomy, fan-outs you've built everywhere since lab 26, and the confidence to extend a resource without touching its code. After this, section two's meta-argument toolbox is complete.

---

## S004 — CONCEPT: Where to find this lab

**Where to find this lab**

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-02-meta-arguments
          └── 50-dynamic-multi

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-02-meta-arguments/50-dynamic-multi
```

You'll find this lab in the course GitHub repository under Section 2, Meta-arguments — the lab named 50-dynamic-multi. The direct link is in the video description. One main dot T F — the terraform block is inline at the top.

---

## S005 — CODE

No separate terraform dot T F this time — the tooling block is inline at the top of main dot T F: Terraform 1.5 or newer, and the azurerm provider around version 3.70. The provider block below bridges to Azure; the empty features block enables the provider's defaults.

---

## S006 — CODE

**Steps:**

1. First list: rules — the lab-41 type contract again. Every entry must carry a name, a priority, and a port; Terraform checks the shape before anything runs.
   - active: [24, 25, 26, 27, 28]
2. And the default ships two entries: Allow SSH on 22 with priority 200, Allow HTTPS on 443 with priority 210. Two entries — two security_rule blocks will be generated.
   - active: [29, 30, 31]

First list: rules — the lab-41 type contract again. Every entry must carry a name, a priority, and a port; Terraform checks the shape before anything runs. And the default ships two entries: Allow SSH on 22 with priority 200, Allow HTTPS on 443 with priority 210. Two entries — two security_rule blocks will be generated.

---

## S007 — CODE

**Steps:**

1. Second list: ip configs — same contract style, but the fields are NIC-shaped: a name, a primary flag, and a static ip.
   - active: [37, 38, 39, 40, 41]
2. The default: ipconfig one — primary, on 172.22.0.10 — and ipconfig two, not primary, on 172.22.0.11. Two entries — two ip_configuration blocks, two addresses on one NIC.
   - active: [42, 43, 44]

Second list: ip configs — same contract style, but the fields are NIC-shaped: a name, a primary flag, and a static ip. The default: ipconfig one — primary, on 172.22.0.10 — and ipconfig two, not primary, on 172.22.0.11. Two entries — two ip_configuration blocks, two addresses on one NIC.

---

## S008 — CODE

**Steps:**

1. Locals, and the now-familiar smaller blocks: VNet on a /20, subnet on a /26 — sizes only have to nest, as lab 47 established.
   - active: [51, 52, 53]

Locals, and the now-familiar smaller blocks: VNet on a /20, subnet on a /26 — sizes only have to nest, as lab 47 established.

---

## S009 — CODE

**Steps:**

1. The base: resource group from local dot rg — the locals set it to rg dash dynamic multi — and VNet vnet dash dynamic multi on the /20.
   - active: [58, 64, 67]
2. And the subnet: snet web on the /26 — the target the NIC's ip configurations will attach to.
   - active: [72, 75]

The base: resource group from local dot rg — the locals set it to rg dash dynamic multi — and VNet vnet dash dynamic multi on the /20. And the subnet: snet web on the /26 — the target the NIC's ip configurations will attach to.

---

## S010 — CODE

**Steps:**

1. The NSG head looks ordinary: nsg dash dynamic multi, location and group from the resource group.
   - active: [79, 80]
2. And the FIRST dynamic — identical to lab 41's. Dynamic security rule, for each over the rules variable, and inside content the fields bind from security rule dot value — name, priority, and the port through tostring. One block, stamped twice.
   - active: [84, 85, 87, 93]

The NSG head looks ordinary: nsg dash dynamic multi, location and group from the resource group. And the FIRST dynamic — identical to lab 41's. Dynamic security rule, for each over the rules variable, and inside content the fields bind from security rule dot value — name, priority, and the port through tostring. One block, stamped twice.

---

## S011 — CODE

**Steps:**

1. The NIC head: nic dash dynamic multi — same three header lines as the NSG.
   - active: [101, 102]
2. And the SECOND dynamic — different label, same shape. Dynamic ip configuration, for each over ip configs. Inside content: the name from ip configuration dot value, subnet id pointing at snet web, STATIC allocation with the explicit address from value dot static ip — and primary from the flag. Note the iterator: ip configuration dot value, because the block label scopes it — not each dot value.
   - active: [106, 107, 109, 111, 112, 113]

The NIC head: nic dash dynamic multi — same three header lines as the NSG. And the SECOND dynamic — different label, same shape. Dynamic ip configuration, for each over ip configs. Inside content: the name from ip configuration dot value, subnet id pointing at snet web, STATIC allocation with the explicit address from value dot static ip — and primary from the flag. Note the iterator: ip configuration dot value, because the block label scopes it — not each dot value.

---

## S012 — CODE

**Steps:**

1. Two outputs. Rule names — a for expression over the rules variable, same as lab 41.
   - active: [120]
2. And nic ips — the NIC's private ip addresses attribute, a provider-computed LIST. One address per generated ip configuration — proof, straight from state, that the dynamic block landed both.
   - active: [122]

Two outputs. Rule names — a for expression over the rules variable, same as lab 41. And nic ips — the NIC's private ip addresses attribute, a provider-computed LIST. One address per generated ip configuration — proof, straight from state, that the dynamic block landed both.

---

## S013 — DYNAMIC_BLOCK: Two dynamic blocks — one NSG, one NIC

**Two dynamic blocks — one NSG, one NIC**

**Steps:**

1. Dynamic number one sits on the NSG: security rule, driven by the rules list — two rule blocks by default.
2. Dynamic number two sits on the NIC — ip configuration over the ip configs list, with the static IP and primary flag as fields.
3. Together: two resources, four generated nested blocks — two rules on the NSG, two ip configurations on the NIC. Extend either list in tfvars, re-apply, and the anatomy follows the data. No code changes.

Dynamic number one sits on the NSG: security rule, driven by the rules list — two rule blocks by default. Dynamic number two sits on the NIC — ip configuration over the ip configs list, with the static IP and primary flag as fields. Together: two resources, four generated nested blocks — two rules on the NSG, two ip configurations on the NIC. Extend either list in tfvars, re-apply, and the anatomy follows the data. No code changes.

---

## S014 — DIAGRAM: How the pieces connect

**How the pieces connect**

**Steps:**

1. Here's how the pieces connect.
2. The two variables: rules and ip configs — the lists that own the anatomy.
   - active: ['vars']
3. The network base: resource group, VNet, subnet.
   - active: ['rg', 'vnet']
4. The NSG: dynamic security_rule — one block per rule in the list.
   - active: ['nsg']
5. The NIC: dynamic ip_configuration — one block per entry, each with a static IP, attached to the subnet.
   - active: ['nic']
6. Outputs report both: rule names from the variable, and the NIC's private IP list from state.
   - active: ['out']
7. Everything lands inside your Azure subscription.

Here's how the pieces connect. The two variables: rules and ip configs — the lists that own the anatomy. The network base: resource group, VNet, subnet. The NSG: dynamic security_rule — one block per rule in the list. The NIC: dynamic ip_configuration — one block per entry, each with a static IP, attached to the subnet. Outputs report both: rule names from the variable, and the NIC's private IP list from state. Everything lands inside your Azure subscription.

---

## S015 — TERMINAL

Here's the plan — terraform plan, an illustrative view. Five to add: resource group, VNet, subnet, NSG, NIC. Inside the NSG: two generated security rule blocks. Inside the NIC: two ip configurations with the static addresses. The plan reads exactly as if you'd hand-written all four.

---

## S016 — TERMINAL

And the outputs — an illustrative view. Rule names: Allow SSH and Allow HTTPS. Nic ips: 172.22.0.10 and 172.22.0.11 — both addresses on one machine, one per generated ip configuration.

---

## S017 — CONCEPT: Common pitfall

- The iterator is the BLOCK label's value — security_rule.value / ip_configuration.value, never each.value
- Multi-IP NIC: exactly ONE ip_configuration has primary = true
- Dynamic trades readability for flexibility — small fixed sets are clearer as plain blocks

**Common pitfall**

Three pitfalls. One: the iterator follows the block label — inside the NSG it's security rule dot value, inside the NIC it's ip configuration dot value; reaching for each dot value is the classic dynamic-block error. Two: multi-IP NICs — static allocation with an explicit address, and EXACTLY one configuration marked primary; Azure refuses zero or two. Three: judgment, straight from the README — dynamic blocks trade readability for flexibility. For a handful of fixed blocks, plain code is easier to debug; reach for dynamic when the count is genuinely caller-owned.

---

## S018 — RECAP

- Two independent dynamic blocks — security_rule on the NSG, ip_configuration on the NIC
- The iterator is the block label's value — security_rule.value / ip_configuration.value
- Multi-IP NIC: Static + explicit private_ip_address, exactly one primary
- nic_ips output reads private_ip_addresses — one address per generated config
- Both lists are caller-owned: extend the variable, apply, the anatomy follows

Quick recap — five things. One: two dynamic blocks in one configuration, each driven by its own list. Two: the iterator is the block label's value — scope it by the label, not each. Three: the multi-IP pattern — static, explicit address, one primary. Four: the nic ips output proves the fan-out straight from state. Five: both lists are caller-owned — the section's whole theme in one lab. That closes the meta-argument toolbox: count, for each, lifecycle, provider, dynamic, and everything between.

---

## S019 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

---

## S020 — CONCEPT: Thanks for watching

**Thanks for watching**

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-02-meta-arguments/50-dynamic-multi
```

Thanks for watching. If this helped, the full lab — along with every lab in this course — is in the GitHub repository linked in the description. See you in the next one.

---
