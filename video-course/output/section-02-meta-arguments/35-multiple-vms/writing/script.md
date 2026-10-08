# Script — Lab 35: Two Rows That Match: count Across Two Resources

*Terraform Meta-arguments — Lab 35. Generated from `source/terraform-inventory.json` + `source/source-manifest.json` (ACTIVE_LAB = `section-02-meta-arguments/35-multiple-vms`).*

---

## S001 — TITLE: Two Rows That Match: count Across Two Resources

**Two Rows That Match: count Across Two Resources**

Welcome back. Labs 28 to 34 were for_each country — names and keys everywhere. This is Lab 35, and count returns for its classic idiom: two resources sharing one count, paired by index. Two NICs, two VMs, and VM number one uses NIC number one. We'll also meet the full anatomy of a Linux VM block — three nested blocks you'll see in every VM lab from here on. Let's build it.

---

## S002 — CONCEPT: What you'll learn

- Two resources sharing one count — instances pair up by index
- count.index threads through: NIC[count.index] inside the VM
- A required sensitive variable — plus the VM's nested blocks

**What you'll learn**

Three things in this lesson. One: two resources — NICs and VMs — sharing the same count, so their instances pair up by index. Two: count dot index threading through the dependency — the VM reaches into the NIC list with the very same index. Three: the infrastructure around it — a required sensitive variable for the SSH key, and the three nested blocks every Linux VM carries.

---

## S003 — CONCEPT: Where this lab fits

- Labs 28–34: for_each paired copies by KEY
- This lab: the count idiom — pairing by INDEX, and its weakness
- First VM of section 2 — the nested-block anatomy matters later

**Where this lab fits**

Placement. The last labs paired copies by key — subnet web to NSG web, by name. This lab shows the count version: pairing by position. It works, and it's everywhere in real code — but it has a weakness we'll name plainly in the pitfall scene. This is also the first virtual machine in section 2, so the VM block's nested anatomy gets a proper walkthrough — it returns in every compute lab ahead.

---

## S004 — CONCEPT: Where to find this lab

**Where to find this lab**

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-02-meta-arguments
          └── 35-multiple-vms

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-02-meta-arguments/35-multiple-vms
```

You'll find this lab in the course GitHub repository under Section 2, Meta-arguments — the lab named 35-multiple-vms. The direct link is in the video description. Main dot T F holds everything — variables included — and terraform dot T F pins the providers.

---

## S005 — CODE

Two files matter here, and the first is terraform dot T F. It pins the tooling: Terraform 1.5 or newer, and the azurerm provider around version 3.70 — nothing else, because this lab needs no extras. The provider block at the bottom is the bridge to Azure; the empty features block enables the provider's default behaviours. That's the whole file — every interesting line lives in main dot T F.

---

## S006 — CODE

**Steps:**

1. Three variables set the stage. vm count is a number with a default of two — the knob that sizes both fan-outs.
   - active: [10, 11, 12, 13]
2. Admin username defaults to azureadmin — one name reused in the SSH key block further down.
   - active: [15, 16, 17, 18]
3. And admin SSH key is required — no default — and marked sensitive. Terraform prompts for it, or you pass it with dash var; sensitive keeps the value out of the plan and apply output.
   - active: [20, 21, 22, 23]
4. A one-line locals block gives the resource group its name — and we're ready to build.
   - active: [24, 25]

Three variables set the stage. vm count is a number with a default of two — the knob that sizes both fan-outs. Admin username defaults to azureadmin — one name reused in the SSH key block further down. And admin SSH key is required — no default — and marked sensitive. Terraform prompts for it, or you pass it with dash var; sensitive keeps the value out of the plan and apply output. A one-line locals block gives the resource group its name — and we're ready to build.

---

## S007 — CODE

**Steps:**

1. The network base: resource group, virtual network on 10.190 slash 16, and one subnet — snet web on 10.190.1.0 slash 24. Nothing counted here — the networking is shared by every VM.
   - active: [29, 35, 38, 43, 46]

The network base: resource group, virtual network on 10.190 slash 16, and one subnet — snet web on 10.190.1.0 slash 24. Nothing counted here — the networking is shared by every VM.

---

## S008 — CODE

**Steps:**

1. The first counted resource: the NIC block, count equals var dot vm count. With the default two, Terraform expands this into two instances — web[0] and web[1].
   - active: [51]
2. Their names carry the index: nic dash vm dash dollar-brace count dot index — nic-vm-0 and nic-vm-1. Each attaches to the same subnet with a dynamic private IP.
   - active: [52, 57, 58]

The first counted resource: the NIC block, count equals var dot vm count. With the default two, Terraform expands this into two instances — web[0] and web[1]. Their names carry the index: nic dash vm dash dollar-brace count dot index — nic-vm-0 and nic-vm-1. Each attaches to the same subnet with a dynamic private IP.

---

## S009 — ITERATION_EXPANSION: One count, two resources, index pairing

**One count, two resources, index pairing**

**Steps:**

1. One expression drives both fan-outs: count equals var dot vm count.
2. The NIC block expands first — instance zero and instance one, named from count dot index.
3. And the VM block expands with the same count — VM i reaches into the NIC list with the same index, so VM zero gets NIC zero, VM one gets NIC one. Position is the pairing.

One expression drives both fan-outs: count equals var dot vm count. The NIC block expands first — instance zero and instance one, named from count dot index. And the VM block expands with the same count — VM i reaches into the NIC list with the same index, so VM zero gets NIC zero, VM one gets NIC one. Position is the pairing.

---

## S010 — CODE

**Steps:**

1. The VM block carries the same count — var dot vm count again — so it expands to exactly as many instances as the NIC block did.
   - active: [64]
2. And here is the idiom this lab exists for: network interface ids takes a LIST containing one element — azurerm_network_interface dot web, bracket, count dot index, dot id. Instance zero reads NIC zero; instance one reads NIC one. The same index on both sides is the whole pairing.
   - active: [70]
3. The first nested block: admin SSH key — username and public key, the key coming from the sensitive variable. Nested blocks live inside the resource and repeat per instance.
   - active: [73, 74, 75, 76]
4. Then os disk — ReadWrite caching on standard SSD — and source image reference: publisher, offer, SKU, version pinning Ubuntu 22.04. These three nested blocks are the anatomy of every Linux VM from here on.
   - active: [78, 79, 80, 81, 83, 84, 85, 86, 87, 88]

The VM block carries the same count — var dot vm count again — so it expands to exactly as many instances as the NIC block did. And here is the idiom this lab exists for: network interface ids takes a LIST containing one element — azurerm_network_interface dot web, bracket, count dot index, dot id. Instance zero reads NIC zero; instance one reads NIC one. The same index on both sides is the whole pairing. The first nested block: admin SSH key — username and public key, the key coming from the sensitive variable. Nested blocks live inside the resource and repeat per instance. Then os disk — ReadWrite caching on standard SSD — and source image reference: publisher, offer, SKU, version pinning Ubuntu 22.04. These three nested blocks are the anatomy of every Linux VM from here on.

---

## S011 — CONCEPT: Index pairing vs key pairing

- count pairs by POSITION: VM[i] ↔ NIC[i] — same index, both sides
- for_each pairs by KEY: this[each.key] — same name, both sides
- Positions shift when the count changes; keys don't

**Index pairing vs key pairing**

Put the two idioms side by side. Count pairs by position: the VM asks for NIC bracket count dot index — whatever sits at that position. for_each pairs by key: the association asked for subnet bracket each dot key — whatever carries that name. The difference shows when the collection changes. Keys are stable: remove app and web still means web. Positions shift: change vm count from two to three and every address stays numbered zero, one, two — but remove the FIRST nic and every VM's pairing slides by one. Same lesson as labs 26 and 27, now with consequences that reach across resources.

---

## S012 — DIAGRAM: How the pieces connect

**How the pieces connect**

**Steps:**

1. Here's how the pieces connect.
2. The variables set the knobs: vm count, username, and the sensitive SSH key.
   - active: ['vars']
3. The resource group groups everything in Azure.
   - active: ['rg']
4. The virtual network and subnet hold 10.190.1.0 slash 24.
   - active: ['vnet']
5. The NICs: count expands one block into two, named from count.index.
   - active: ['nics']
6. The VMs: the same count — and each VM grabs its NIC by index: bracket count dot index inside the list.
   - active: ['vms']
7. Everything lands inside your Azure subscription.

Here's how the pieces connect. The variables set the knobs: vm count, username, and the sensitive SSH key. The resource group groups everything in Azure. The virtual network and subnet hold 10.190.1.0 slash 24. The NICs: count expands one block into two, named from count.index. The VMs: the same count — and each VM grabs its NIC by index: bracket count dot index inside the list. Everything lands inside your Azure subscription.

---

## S013 — TERMINAL

Here's the plan — terraform plan, an illustrative view. Resource group, VNet, subnet, then the counted pairs: NIC bracket zero and bracket one, VM bracket zero and bracket one. Look inside VM zero — the admin SSH key's public key reads sensitive value, redacted because the variable is marked sensitive. Seven to add, zero to destroy.

---

## S014 — CONCEPT: Common pitfall

- Index pairing slides: remove item 0 and every pairing shifts
- sensitive = true hides CLI output — the value is still in state
- This lab creates no public IP — the VMs are private-only

**Common pitfall**

Three pitfalls. One: the fragility we named earlier — index pairing slides. Remove the first NIC and every VM suddenly pairs with the wrong one; for_each by key has no such failure mode. Two: sensitive equals true hides the key from plan and apply output — it does NOT encrypt state; the value sits in the state file in plain text, so protect the file. Three: this config creates no public IP — these VMs are reachable only from inside the network; if you want to SSH in, you'll need to add a path — which is exactly what later labs do.

---

## S015 — RECAP

- Two resources share count = var.vm_count — same size fan-outs
- count.index names both sides: nic-vm-N and vm-web-N
- VM[i] gets NIC[i] via azurerm_network_interface.web[count.index].id
- A required sensitive variable has no default — Terraform prompts
- Nested blocks — admin_ssh_key, os_disk, source_image_reference

Quick recap — five things. One: NICs and VMs share the same count, driven by one variable. Two: count dot index names both sides — nic dash vm dash N, vm dash web dash N. Three: the pairing itself is one expression — VM i reads NIC bracket count dot index dot id. Four: the SSH key variable is required and sensitive — no default, prompted at apply, hidden in output. Five: every VM carries three nested blocks — admin SSH key, os disk, source image reference — the anatomy you'll see in every compute lab ahead. Count pairing: simple, and now you know exactly when it bends.

---

## S016 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

---

## S017 — CONCEPT: Thanks for watching

**Thanks for watching**

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-02-meta-arguments/35-multiple-vms
```

Thanks for watching. If this helped, the full lab — along with every lab in this course — is in the GitHub repository linked in the description. See you in the next one.

---
